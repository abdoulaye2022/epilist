<?php
// src/Services/ClientIp.php — l'adresse de la personne qui appelle, et
// pas celle qu'elle pretend avoir.
//
// LE PROBLEME. Les plafonds de cadence (connexion, codes a six chiffres,
// formulaire de contact) comptent les essais PAR ADRESSE IP. Jusqu'ici,
// cette adresse etait lue d'abord dans X-Forwarded-For — un en-tete que
// le client ecrit lui-meme. Il suffisait d'y mettre une valeur
// differente a chaque requete pour etre une adresse neuve a chaque
// essai, et aucun plafond « par IP » ne tenait plus.
//
// LA REGLE. On ne croit un en-tete transmis QUE si la requete arrive
// d'un mandataire connu. Deux facons de le savoir :
//
//   1. TRUSTED_PROXIES dans .env : adresses ou blocs CIDR, separes par
//      des virgules. Si REMOTE_ADDR en fait partie, on lit
//      X-Forwarded-For de DROITE a GAUCHE et on garde la premiere
//      adresse qui n'est pas un mandataire : c'est celle que le dernier
//      mandataire a vue arriver. Les valeurs a gauche, c'est le client
//      qui les a ecrites ; elles ne valent rien.
//
//   2. Sans TRUSTED_PROXIES : si REMOTE_ADDR est une adresse PRIVEE
//      (10.x, 172.16-31.x, 192.168.x, fc00::/7, 127.x), la requete
//      vient forcement d'un equipement de l'infrastructure, pas
//      d'Internet — c'est le cas sur un hebergement mutualise ou un
//      repartiteur se tient devant PHP. On applique alors la meme
//      lecture de droite a gauche. Si REMOTE_ADDR est publique, c'est
//      le client lui-meme : on la garde, et on ignore tout en-tete.
//
// Pourquoi ne pas simplement ignorer X-Forwarded-For ? Parce que derriere
// un repartiteur, REMOTE_ADDR est la meme pour tout le monde : dix
// echecs de connexion de n'importe qui bloqueraient tous les autres.
// Le remede serait pire que le mal.

namespace App\Services;

use Psr\Http\Message\ServerRequestInterface as Request;

final class ClientIp
{
    /** Blocs qui designent un reseau interne, jamais un client d'Internet. */
    private const RESEAUX_PRIVES = [
        '10.0.0.0/8',
        '172.16.0.0/12',
        '192.168.0.0/16',
        '127.0.0.0/8',
        '169.254.0.0/16',
        'fc00::/7',
        '::1/128',
    ];

    /** L'adresse du client pour cette requete. Toujours une IP valide, ou 0.0.0.0. */
    public static function depuis(Request $request): string
    {
        $serveur = $request->getServerParams();
        $directe = self::valide((string) ($serveur['REMOTE_ADDR'] ?? ''));

        $mandataires = self::mandatairesDeConfiance();
        $directeEstMandataire = $directe !== null && (
            $mandataires !== []
                ? self::dansLesBlocs($directe, $mandataires)
                : self::dansLesBlocs($directe, self::RESEAUX_PRIVES)
        );

        if (!$directeEstMandataire) {
            return $directe ?? '0.0.0.0';
        }

        // Derriere un mandataire : on remonte la chaine de droite a
        // gauche, et on s'arrete a la premiere adresse qui n'en est pas un.
        $blocs = $mandataires !== [] ? $mandataires : self::RESEAUX_PRIVES;
        $chaine = $request->getHeaderLine('X-Forwarded-For');

        if ($chaine !== '') {
            foreach (array_reverse(explode(',', $chaine)) as $saut) {
                $ip = self::valide(trim($saut));
                if ($ip !== null && !self::dansLesBlocs($ip, $blocs)) {
                    return $ip;
                }
            }
        }

        // Pas de X-Forwarded-For exploitable : un mandataire peut aussi
        // poser une seule adresse dans X-Real-IP ou CF-Connecting-IP.
        foreach (['X-Real-IP', 'CF-Connecting-IP'] as $entete) {
            $ip = self::valide(trim($request->getHeaderLine($entete)));
            if ($ip !== null && !self::dansLesBlocs($ip, $blocs)) {
                return $ip;
            }
        }

        return $directe ?? '0.0.0.0';
    }

    /** Les mandataires declares dans .env (TRUSTED_PROXIES), ou []. */
    public static function mandatairesDeConfiance(): array
    {
        $brut = (string) ($_ENV['TRUSTED_PROXIES'] ?? '');
        if (trim($brut) === '') {
            return [];
        }

        return array_values(array_filter(array_map('trim', explode(',', $brut))));
    }

    /** L'adresse si elle est syntaxiquement valide, sinon null. */
    private static function valide(string $ip): ?string
    {
        return filter_var($ip, FILTER_VALIDATE_IP) === false ? null : $ip;
    }

    /** Cette adresse appartient-elle a l'un des blocs (IP seule ou CIDR) ? */
    public static function dansLesBlocs(string $ip, array $blocs): bool
    {
        foreach ($blocs as $bloc) {
            if (self::dansLeBloc($ip, $bloc)) {
                return true;
            }
        }

        return false;
    }

    private static function dansLeBloc(string $ip, string $bloc): bool
    {
        if (!str_contains($bloc, '/')) {
            return inet_pton($ip) !== false && inet_pton($bloc) !== false
                && inet_pton($ip) === inet_pton($bloc);
        }

        [$reseau, $bits] = explode('/', $bloc, 2);
        $ipBin = inet_pton($ip);
        $reseauBin = inet_pton($reseau);

        if ($ipBin === false || $reseauBin === false || strlen($ipBin) !== strlen($reseauBin)) {
            return false; // IPv4 contre IPv6 : jamais dans le meme bloc.
        }

        $bits = (int) $bits;
        $octetsPleins = intdiv($bits, 8);
        $bitsRestants = $bits % 8;

        if ($octetsPleins > 0 && substr($ipBin, 0, $octetsPleins) !== substr($reseauBin, 0, $octetsPleins)) {
            return false;
        }

        if ($bitsRestants === 0) {
            return true;
        }

        $masque = (0xFF << (8 - $bitsRestants)) & 0xFF;

        return (ord($ipBin[$octetsPleins]) & $masque) === (ord($reseauBin[$octetsPleins]) & $masque);
    }
}
