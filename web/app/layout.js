export const metadata = {
  title: "Instagram Wrapped",
}

export default function RootLayout({ children }) {
  return (
    <html lang="en">
      <body style={{ margin: 0, background: "#0B0B0D", color: "#FFFFFF" }}>{children}</body>
    </html>
  )
}
