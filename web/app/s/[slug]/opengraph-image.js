import { ImageResponse } from "@vercel/og"
import { loadSnapshot } from "../../../lib/snapshot.js"

export const alt = "Instagram Wrapped"
export const size = { width: 1200, height: 630 }
export const contentType = "image/png"

export default async function Image({ params }) {
  const { slug } = await params
  const snapshot = await loadSnapshot(slug)
  const src = snapshot ? await dataUrl(snapshot.imageUrl) : null
  if (!src) {
    return new ImageResponse(
      <div style={{ background: "#0B0B0D", width: "100%", height: "100%" }} />,
      { ...size }
    )
  }

  return new ImageResponse(
    <div
      style={{
        background: "#0B0B0D",
        width: "100%",
        height: "100%",
        display: "flex",
        alignItems: "center",
        justifyContent: "center",
      }}
    >
      <img src={src} height={590} style={{ objectFit: "contain" }} />
    </div>,
    { ...size }
  )
}

async function dataUrl(imageUrl) {
  const response = await fetch(imageUrl)
  if (!response.ok) return null
  const bytes = new Uint8Array(await response.arrayBuffer())
  let binary = ""
  const chunk = 0x8000
  for (let index = 0; index < bytes.length; index += chunk) {
    binary += String.fromCharCode(...bytes.subarray(index, index + chunk))
  }
  return `data:image/png;base64,${btoa(binary)}`
}
