"use client";

interface TrackingButtonProps {
  onClick: () => void;
  children: React.ReactNode;
  trackingData: {
    platform: "ios" | "android";
    source: "cta_section" | "footer";
  };
  className?: string;
  variant?: "default" | "outline";
}

import { trackAppDownload } from "@/lib/gtag";
import { Button } from "@/components/ui/button";

export default function TrackingButton({
  onClick,
  children,
  trackingData,
  className,
  variant = "default",
}: TrackingButtonProps): JSX.Element {
  const handleClick = (): void => {
    trackAppDownload(trackingData.platform, trackingData.source);
    onClick();
  };

  return (
    <Button
      onClick={handleClick}
      className={className}
      variant={variant}
      data-download-tracking={`${trackingData.platform}-${trackingData.source}`}
    >
      {children}
    </Button>
  );
}
