// components/ui/Card.tsx - COMPOSANT CARTE
import { cn } from "@/app/lib/utils";
import React from "react";

interface CardProps extends React.HTMLAttributes<HTMLDivElement> {
  children: React.ReactNode;
}

export function Card({ className, children, ...props }: CardProps) {
  return (
    <div
      className={cn(
        "bg-white rounded-2xl shadow-xl border border-gray-100 p-6",
        className
      )}
      style={{
        backgroundColor: "white",
        borderRadius: "1rem",
        boxShadow: "0 25px 50px -12px rgba(0, 0, 0, 0.25)",
        border: "1px solid #f3f4f6",
        padding: "1.5rem",
      }}
      {...props}
    >
      {children}
    </div>
  );
}
