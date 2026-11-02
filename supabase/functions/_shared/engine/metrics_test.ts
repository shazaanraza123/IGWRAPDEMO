import { parsePersona } from "../../../../data/schema.ts";
import { computeMetrics, reelsCategoryMethod, type Metric, type MetricSource } from "./metrics.ts";

const window = { start: "2026-01-01", end: "2026-11-15" };

function rows(metrics: Metric[], key: string) {
  return metrics.filter((metric) => metric.key === key);
}

function one(metrics: Metric[], key: string) {
  const found = rows(metrics, key);
  if (found.length !== 1) throw new Error(`${key} has ${found.length} rows`);
  return found[0];
}

function num(metrics: Metric[], key: string) {
  const metric = one(metrics, key);
  if (metric.value_num === null) throw new Error(`${key} has no number`);
  return metric.value_num;
}

async function persona(key: string) {
  const file = new URL(`../../../../data/personas/${key}.json`, import.meta.url);
  return parsePersona(JSON.parse(await Deno.readTextFile(file)));
}

Deno.test("maya metrics cover every number the 13 cards use", async () => {
  const maya = await persona("maya");
  const metrics = computeMetrics(maya, maya.window);

  for (const metric of metrics) {
    if (!metric.method || !metric.provenance || !metric.window_start || !metric.window_end) {
      throw new Error(`${metric.key} is missing provenance, method, or window`);
    }
  }
  if (metrics.some((metric) => metric.key.includes("archetype") || metric.value_text === "curator")) {
    throw new Error("archetype scores belong in the next step");
  }

  if (num(metrics, "posts") !== 38) throw new Error("posts");
  if (num(metrics, "stories") !== 412) throw new Error("stories");
  if (num(metrics, "reels_sent") !== 1206) throw new Error("reels sent");
  if (num(metrics, "saves") !== 1214) throw new Error("saves");
  if (num(metrics, "days_active") !== 301) throw new Error("days active");
  if (num(metrics, "liked_posts") !== 1840) throw new Error("liked posts");
  if (num(metrics, "friends_stories_watched_pct") !== 96) throw new Error("stories watched");

  const monthPosts = rows(metrics, "monthly_posts");
  const monthStories = rows(metrics, "monthly_stories");
  if (monthPosts.length !== 11 || monthStories.length !== 11) throw new Error("monthly rows");
  const postSum = monthPosts.reduce((sum, metric) => sum + (metric.value_num ?? 0), 0);
  const storySum = monthStories.reduce((sum, metric) => sum + (metric.value_num ?? 0), 0);
  if (postSum !== 38 || storySum !== 412) throw new Error("monthly sums");
  if (num(metrics, "top_month") !== 8 || one(metrics, "top_month").value_text !== "August") {
    throw new Error("top month");
  }
  if (num(metrics, "top_month_posts") !== 9 || num(metrics, "top_month_stories") !== 61) {
    throw new Error("August counts");
  }
  if (num(metrics, "months_covered") !== 11) throw new Error("months covered");

  const swatches = rows(metrics, "feed_swatch");
  const swatchSum = swatches.reduce((sum, metric) => sum + (metric.value_num ?? 0), 0);
  if (swatches.length !== 5 || swatchSum !== 100) throw new Error("swatches");
  if (swatches[0].value_text !== "#1F2A44" || swatches[0].value_num !== 31) throw new Error("first swatch");

  const topics = rows(metrics, "explore_topic");
  if (topics.map((metric) => metric.value_text).join(",") !== "Streetwear drops,Film cameras,Ceramic frogs") {
    throw new Error("topic order");
  }
  if (topics.some((metric) => metric.provenance !== "inferred")) throw new Error("topics are inferred");
  const watched = one(metrics, "explore_topic_watched");
  if (watched.value_num !== 63 || watched.value_text !== "Ceramic frogs") throw new Error("watched");

  const shares = rows(metrics, "reels_category_share");
  const shareSum = shares.reduce((sum, metric) => sum + (metric.value_num ?? 0), 0);
  if (shares.length !== 5 || shareSum !== 92) throw new Error("reels shares");
  const reelsMethod = reelsCategoryMethod(8);
  if (reelsMethod !== "Top 5 categories by share of your Reels watch time. Other categories: 8%.") {
    throw new Error("reels method wording");
  }
  if (shares.some((metric) => metric.method !== reelsMethod)) throw new Error("reels method on each share");
  if (metrics.some((metric) => metric.value_text === "Other" || metric.key.includes("other"))) {
    throw new Error("other reels share must not be a row");
  }
  if (one(metrics, "top_reels_category").value_text !== "Streetwear") throw new Error("top interest");
  if (num(metrics, "fastest_rising_multiple") !== 4) throw new Error("rising multiple");
  if (num(metrics, "fastest_rising_since_month") !== 6 || num(metrics, "plot_turn_month") !== 6) {
    throw new Error("turn month");
  }
  if (one(metrics, "plot_turn_month").value_text !== "June") throw new Error("June");

  const bars = rows(metrics, "ceramics_monthly");
  if (bars.map((metric) => metric.value_num).join(",") !== "3,2,4,3,5,22,41,58,64,71,80") {
    throw new Error("ceramics series");
  }
  if (one(metrics, "plot_category").value_text !== "Ceramics") throw new Error("plot category");

  if (num(metrics, "main_post_likes") !== 2184) throw new Error("likes");
  if (num(metrics, "main_post_comments") !== 418) throw new Error("comments");
  if (num(metrics, "main_post_avg_likes") !== 728) throw new Error("average likes");
  if (num(metrics, "main_post_vs_average") !== 3) throw new Error("versus average");
  if (one(metrics, "main_post_posted_at").value_text !== "2026-07-19") throw new Error("posted at");
  const replies = one(metrics, "story_replies_24h");
  if (replies.value_num !== 47 || replies.window_start !== "2026-03-14" || replies.window_end !== "2026-03-15") {
    throw new Error("story replies window");
  }

  const circle = rows(metrics, "circle_member").map((metric) => metric.value_text);
  if (circle.join(",") !== "dee.films,jules.mp,nico_k,sam.wav,tori.eats") throw new Error("circle order");
  if (rows(metrics, "circle_member").some((metric) => metric.value_num !== null)) {
    throw new Error("circle has no counts");
  }

  if (one(metrics, "latest_local_time").value_text !== "03:42") throw new Error("latest time");
  if (one(metrics, "latest_session_weekday").value_text !== "Tuesday") throw new Error("weekday");
  if (num(metrics, "latest_session_month") !== 5 || one(metrics, "latest_session_month").value_text !== "May") {
    throw new Error("May");
  }

  const yearScoped = one(metrics, "posts");
  if (yearScoped.window_start !== "2026-01-01" || yearScoped.window_end !== "2026-11-15") {
    throw new Error("year window");
  }
});

Deno.test("teen matches maya and identity-only personas have no metrics", async () => {
  const maya = await persona("maya");
  const teen = await persona("teen");
  const mayaMetrics = computeMetrics(maya, maya.window);
  const teenMetrics = computeMetrics(teen, teen.window);
  if (JSON.stringify(mayaMetrics) !== JSON.stringify(teenMetrics)) {
    throw new Error("teen metrics differ from maya");
  }
  for (const key of ["ghost", "connector", "emerging", "established"]) {
    const source = await persona(key);
    if (computeMetrics(source, source.window).length !== 0) {
      throw new Error(`${key} invented metrics`);
    }
  }
});

Deno.test("top month, ratio, and window are computed", () => {
  const tied: MetricSource = {
    monthly: [
      { month: 1, posts: 5, stories: 1 },
      { month: 2, posts: 5, stories: 9 },
    ],
  };
  if (num(computeMetrics(tied, window), "top_month") !== 2) throw new Error("tie break");

  const divided = computeMetrics({
    main_character_post: { id: "p", posted_at: "2026-01-02", likes: 10, comments: 1, avg_likes: 4 },
  }, window);
  if (num(divided, "main_post_vs_average") !== 2.5) throw new Error("ratio");

  const zero = computeMetrics({
    main_character_post: { id: "p", posted_at: "2026-01-02", likes: 10, comments: 1, avg_likes: 0 },
  }, window);
  if (rows(zero, "main_post_vs_average").length !== 0) throw new Error("divide by zero");

  const early = computeMetrics({
    monthly: [
      { month: 6, posts: 4, stories: 40 },
      { month: 8, posts: 9, stories: 61 },
    ],
    ceramics_monthly: [0, 0, 0, 0, 0, 22, 0, 58],
  }, { start: "2026-01-01", end: "2026-06-30" });
  if (num(early, "top_month") !== 6) throw new Error("windowed top month");
  const bars = rows(early, "ceramics_monthly");
  if (bars.map((metric) => metric.value_text).join(",") !== "1,2,3,4,5,6") {
    throw new Error("windowed ceramics");
  }
  if (bars.find((metric) => metric.value_text === "6")?.value_num !== 22) {
    throw new Error("June ceramics");
  }
});
