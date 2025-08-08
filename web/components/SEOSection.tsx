interface SEOSectionProps {
  id: string;
  title: string;
  description: string;
  keywords?: string[];
  children: React.ReactNode;
}

export default function SEOSection({
  id,
  title,
  description,
  keywords = [],
  children,
}: SEOSectionProps) {
  return (
    <section
      id={id}
      itemScope
      itemType="https://schema.org/WebPageElement"
      className="scroll-mt-20"
    >
      <meta itemProp="name" content={title} />
      <meta itemProp="description" content={description} />
      {keywords.length > 0 && (
        <meta itemProp="keywords" content={keywords.join(", ")} />
      )}

      {children}
    </section>
  );
}
