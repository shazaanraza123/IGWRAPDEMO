export async function loadSnapshot(slug) {
  const supabaseURL = process.env.SUPABASE_URL
  const anonKey = process.env.SUPABASE_ANON_KEY
  if (!supabaseURL || !anonKey || !slug) return null

  const endpoint = new URL("/rest/v1/share_snapshots", supabaseURL)
  endpoint.searchParams.set("slug", `eq.${slug}`)
  endpoint.searchParams.set("revoked", "eq.false")
  endpoint.searchParams.set("select", "slug,image_path,alt_text")

  const response = await fetch(endpoint, {
    headers: {
      apikey: anonKey,
      Authorization: `Bearer ${anonKey}`,
    },
    cache: "no-store",
  })
  if (!response.ok) return null

  const rows = await response.json()
  const row = Array.isArray(rows) ? rows[0] : null
  if (!row?.image_path || !row?.alt_text) return null

  const objectPath = String(row.image_path).replace(/^shares\//, "")
  const imageUrl = new URL(
    `/storage/v1/object/public/shares/${objectPath}`,
    supabaseURL
  ).toString()

  return {
    slug: row.slug,
    altText: row.alt_text,
    imageUrl,
  }
}
