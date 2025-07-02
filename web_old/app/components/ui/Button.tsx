// components/ui/Button.tsx - COMPOSANT BOUTON CORRIGÉ
import { cn } from "@/app/lib/utils";
import React from "react";

interface ButtonProps extends React.ButtonHTMLAttributes<HTMLButtonElement> {
  variant?: "default" | "outline" | "ghost";
  size?: "sm" | "md" | "lg";
  children: React.ReactNode;
}

export function Button({
  className,
  variant = "default",
  size = "md",
  children,
  ...props
}: ButtonProps) {
  const getStyles = () => {
    const base = {
      display: "inline-flex",
      alignItems: "center",
      justifyContent: "center",
      borderRadius: "0.5rem",
      fontWeight: "500",
      transition: "all 0.2s",
      cursor: "pointer",
      border: "none",
      outline: "none",
    };

    const variants = {
      default: {
        backgroundColor: "#16a34a",
        color: "white",
        ":hover": {
          backgroundColor: "#15803d",
        },
      },
      outline: {
        backgroundColor: "white",
        color: "#374151",
        border: "1px solid #d1d5db",
        ":hover": {
          backgroundColor: "#f9fafb",
        },
      },
      ghost: {
        backgroundColor: "transparent",
        color: "#374151",
        ":hover": {
          backgroundColor: "#f3f4f6",
        },
      },
    };

    const sizes = {
      sm: { height: "2rem", padding: "0 0.75rem", fontSize: "0.875rem" },
      md: { height: "2.5rem", padding: "0 1rem", fontSize: "1rem" },
      lg: { height: "3rem", padding: "0 1.5rem", fontSize: "1.125rem" },
    };

    return { ...base, ...variants[variant], ...sizes[size] };
  };

  return (
    <button
      className={cn(
        "inline-flex items-center justify-center rounded-lg font-medium transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-offset-2 disabled:pointer-events-none disabled:opacity-50",
        variant === "default" && "bg-green-600 text-white hover:bg-green-700",
        variant === "outline" &&
          "border border-gray-300 bg-white text-gray-700 hover:bg-gray-50",
        variant === "ghost" && "text-gray-700 hover:bg-gray-100",
        size === "sm" && "h-8 px-3 text-sm",
        size === "md" && "h-10 px-4 text-base",
        size === "lg" && "h-12 px-6 text-lg",
        className
      )}
      style={getStyles()}
      {...props}
    >
      {children}
    </button>
  );
}
