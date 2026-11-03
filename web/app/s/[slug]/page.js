import { loadSnapshot } from "../../../lib/snapshot.js"

export const dynamic = "force-dynamic"

export async function generateMetadata({ params }) {
  const { slug } = await params
  const snapshot = await loadSnapshot(slug)
  return {
    title: "Instagram Wrapped",
    description: snapshot?.altText ?? "Concept prototype. Not affiliated with Instagram. Sample data.",
  }
}

export default async function ShareSnapshotPage({ params }) {
  const { slug } = await params
  const snapshot = await loadSnapshot(slug)

  return (
    <main className="landing">
      <style>{`
        .landing {
          min-height: 100vh;
          display: flex;
          flex-direction: column;
          align-items: center;
          justify-content: center;
          gap: 20px;
          padding: 20px;
          background: #0B0B0D;
          color: #FFFFFF;
          font-family: system-ui, sans-serif;
        }
        .landing img {
          max-width: min(100%, 420px);
          max-height: calc(100vh - 160px);
          height: auto;
          object-fit: contain;
        }
        .pill {
          display: inline-flex;
          align-items: center;
          justify-content: center;
          min-height: 50px;
          padding: 0 22px;
          border-radius: 999px;
          background: #FFFFFF;
          color: #0B0B0D;
          font-size: 16px;
          font-weight: 700;
          text-decoration: none;
        }
        .text-link {
          color: #FFFFFF;
          font-size: 14px;
          text-underline-offset: 3px;
        }
        .landing section {
          display: none;
          max-width: 320px;
          text-align: center;
          line-height: 1.4;
        }
        .landing section:target {
          display: block;
        }
        .missing {
          margin: 0;
          font-size: 16px;
        }
      `}</style>
      {snapshot ? (
        <>
          <img src={snapshot.imageUrl} alt={snapshot.altText} />
          <a className="pill" href="#testflight">See yours</a>
          <a className="text-link" href="#about">What&apos;s Instagram Wrapped?</a>
          <section id="testflight">
            <p>Distributed through TestFlight only. Never submitted to the App Store.</p>
          </section>
          <section id="about">
            <p>Instagram Wrapped is a yearly, Story-format recap of a user&apos;s year on Instagram.</p>
            <p>Concept prototype. Not affiliated with Instagram. Sample data.</p>
          </section>
        </>
      ) : (
        <p className="missing">No longer available</p>
      )}
    </main>
  )
}
