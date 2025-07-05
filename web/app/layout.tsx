import './globals.css';
import type { Metadata } from 'next';
import { Inter } from 'next/font/google';
import LanguageProvider from '@/components/LanguageProvider';

const inter = Inter({ subsets: ['latin'] });

export const metadata: Metadata = {
  title: 'EpiList - Simplifiez vos courses',
  description: 'L\'application mobile qui révolutionne votre façon de faire les courses. Créez, partagez et gérez vos listes en famille.',
  keywords: 'courses, épicerie, liste, famille, mobile, app, partage, organisation',
  authors: [{ name: 'EpiList Team' }],
  openGraph: {
    title: 'EpiList - Simplifiez vos courses',
    description: 'L\'application mobile qui révolutionne votre façon de faire les courses.',
    type: 'website',
    locale: 'fr_FR',
  },
  twitter: {
    card: 'summary_large_image',
    title: 'EpiList - Simplifiez vos courses',
    description: 'L\'application mobile qui révolutionne votre façon de faire les courses.',
  },
  robots: {
    index: true,
    follow: true,
  },
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="fr">
      <body className={inter.className}>
        <LanguageProvider>
          {children}
        </LanguageProvider>
      </body>
    </html>
  );
}