/** Numbers for the 13 personal cards. Missing source data produces no metric. */

export type Provenance = "measured" | "estimated" | "inferred";

export type MetricWindow = {
  start: string;
  end: string;
};

export type Metric = {
  key: string;
  value_num: number | null;
  value_text: string | null;
  unit: string | null;
  provenance: Provenance;
  method: string;
  window_start: string;
  window_end: string;
};

export type MetricSource = {
  totals?: {
    posts: number;
    stories: number;
    reels_sent: number;
    saves: number;
    days_active: number;
    liked_posts: number;
    friends_stories_watched_pct: number;
  };
  monthly?: { month: number; posts: number; stories: number }[];
  feed_color?: { swatches: { hex: string; pct: number }[] };
  explore_topics?: { name: string; score: number; watched?: number }[];
  reels_categories?: { name: string; pct: number }[];
  fastest_rising?: { name: string; multiple: number; since_month: number };
  ceramics_monthly?: number[];
  main_character_post?: {
    id: string;
    posted_at: string;
    likes: number;
    comments: number;
    avg_likes: number;
  };
  most_replied_story?: { id: string; posted_at: string; replies_24h: number };
  circle?: { handle: string }[];
  late_night?: { latest_local_time: string; weekday: string; month: number };
};

export function monthName(month: number): string | null {
  return MONTH_NAMES[month - 1] ?? null;
}

const MONTH_NAMES = [
  "January",
  "February",
  "March",
  "April",
  "May",
  "June",
  "July",
  "August",
  "September",
  "October",
  "November",
  "December",
];

const REELS_METHOD_PREFIX = "Top 5 categories by share of your Reels watch time. Other categories: ";

export function reelsCategoryMethod(otherPercent: number) {
  const printed = Number.isInteger(otherPercent) ? String(otherPercent) : String(Math.round(otherPercent * 10) / 10);
  return `${REELS_METHOD_PREFIX}${printed}%.`;
}

function parts(iso: string) {
  const [year, month, day] = iso.split("-").map(Number);
  return { year, month, day };
}

function monthInWindow(month: number, window: MetricWindow) {
  const start = parts(window.start);
  const end = parts(window.end);
  const startIndex = start.year * 12 + start.month;
  const endIndex = end.year * 12 + end.month;
  if (startIndex > endIndex) return false;
  for (let year = start.year; year <= end.year; year++) {
    const index = year * 12 + month;
    if (index >= startIndex && index <= endIndex) return true;
  }
  return false;
}

function addDays(iso: string, days: number) {
  const { year, month, day } = parts(iso);
  const date = new Date(Date.UTC(year, month - 1, day));
  date.setUTCDate(date.getUTCDate() + days);
  return date.toISOString().slice(0, 10);
}

function ratio(numerator: number, denominator: number) {
  const value = numerator / denominator;
  const nearest = Math.round(value);
  if (Math.abs(value - nearest) < 1e-9) return nearest;
  return Math.round(value * 10) / 10;
}

export function computeMetrics(source: MetricSource, window: MetricWindow): Metric[] {
  const metrics: Metric[] = [];
  const add = (
    key: string,
    valueNum: number | null,
    valueText: string | null,
    unit: string | null,
    provenance: Provenance,
    method: string,
    metricWindow: MetricWindow = window,
  ) => {
    metrics.push({
      key,
      value_num: valueNum,
      value_text: valueText,
      unit,
      provenance,
      method,
      window_start: metricWindow.start,
      window_end: metricWindow.end,
    });
  };

  const totals = source.totals;
  if (totals) {
    add("posts", totals.posts, null, "posts", "measured", "Posts you shared in the window.");
    add("stories", totals.stories, null, "stories", "measured", "Stories you shared in the window.");
    add("reels_sent", totals.reels_sent, null, "reels", "measured", "Reels you sent to friends in the window.");
    add("saves", totals.saves, null, "saves", "measured", "Posts you saved in the window.");
    add("days_active", totals.days_active, null, "days", "measured", "Days you were active in the window.");
    add("liked_posts", totals.liked_posts, null, "posts", "measured", "Posts you liked in the window.");
    add(
      "friends_stories_watched_pct",
      totals.friends_stories_watched_pct,
      null,
      "percent",
      "measured",
      "Share of friends' Stories you watched.",
    );
  }

  const months = (source.monthly ?? []).filter((month) => monthInWindow(month.month, window));
  for (const month of months) {
    const label = String(month.month);
    add("monthly_posts", month.posts, label, "posts", "measured", "Posts you shared in this month.");
    add("monthly_stories", month.stories, label, "stories", "measured", "Stories you shared in this month.");
  }
  if (months.length > 0) {
    const top = [...months].sort((a, b) => b.posts - a.posts || b.stories - a.stories || a.month - b.month)[0];
    add("top_month", top.month, MONTH_NAMES[top.month - 1] ?? null, "month", "measured", "Month with the most posts, then the most Stories.");
    add("top_month_posts", top.posts, String(top.month), "posts", "measured", "Posts in your busiest month.");
    add("top_month_stories", top.stories, String(top.month), "stories", "measured", "Stories in your busiest month.");
    add("months_covered", months.length, null, "months", "measured", "Months in the window with a memory.");
  }

  for (const swatch of source.feed_color?.swatches ?? []) {
    add("feed_swatch", swatch.pct, swatch.hex, "percent", "measured", "Share of liked posts with this main color.");
  }

  for (const topic of source.explore_topics ?? []) {
    add("explore_topic", topic.score, topic.name, "score", "inferred", "Your taps tune Explore. Undo in Settings.");
    if (topic.watched !== undefined) {
      add("explore_topic_watched", topic.watched, topic.name, "plays", "inferred", "Times you watched this topic.");
    }
  }

  const categories = [...(source.reels_categories ?? [])].sort((a, b) => b.pct - a.pct).slice(0, 5);
  if (categories.length > 0) {
    const other = 100 - categories.reduce((sum, category) => sum + category.pct, 0);
    const method = reelsCategoryMethod(other);
    for (const category of categories) {
      add("reels_category_share", category.pct, category.name, "percent", "measured", method);
    }
    const leader = categories[0];
    add("top_reels_category", leader.pct, leader.name, "percent", "measured", "The largest share of your Reels watch time.");
  }

  const rising = source.fastest_rising;
  if (rising) {
    add("fastest_rising_multiple", rising.multiple, rising.name, "times", "measured", "How many times this category grew since the turn.");
    add("fastest_rising_since_month", rising.since_month, rising.name, "month", "measured", "Month the fastest-rising category took off.");
    add("plot_turn_month", rising.since_month, MONTH_NAMES[rising.since_month - 1] ?? null, "month", "measured", "Month the fastest-rising category took off.");
  }

  const series = source.ceramics_monthly ?? [];
  series.forEach((value, index) => {
    const month = index + 1;
    if (!monthInWindow(month, window)) return;
    add("ceramics_monthly", value, String(month), "likes_and_saves", "measured", "Likes and saves in Ceramics, by month.");
  });
  if (series.length > 0) {
    add("plot_category", null, "Ceramics", null, "measured", "Likes and saves in this category.");
  }

  const post = source.main_character_post;
  if (post) {
    add("main_post_likes", post.likes, post.id, "likes", "measured", "Likes on your most-liked post in the window.");
    add("main_post_comments", post.comments, post.id, "comments", "measured", "Comments on your most-liked post.");
    add("main_post_avg_likes", post.avg_likes, post.id, "likes", "measured", "Average likes on your posts in the window.");
    if (post.avg_likes > 0) {
      add(
        "main_post_vs_average",
        ratio(post.likes, post.avg_likes),
        post.id,
        "times",
        "measured",
        "Likes on that post divided by your average likes per post.",
      );
    }
    add("main_post_posted_at", null, post.posted_at, null, "measured", "The day you posted your most-liked post.", {
      start: post.posted_at,
      end: post.posted_at,
    });
  }

  const story = source.most_replied_story;
  if (story) {
    add(
      "story_replies_24h",
      story.replies_24h,
      story.id,
      "replies",
      "measured",
      "Replies in the 24 hours after you posted this Story.",
      { start: story.posted_at, end: addDays(story.posted_at, 1) },
    );
  }

  const handles = (source.circle ?? []).map((friend) => friend.handle).sort((a, b) => a.localeCompare(b));
  for (const handle of handles) {
    add("circle_member", null, handle, null, "measured", "Accounts you interacted with. Shown unranked.");
  }

  const night = source.late_night;
  if (night) {
    add("latest_local_time", null, night.latest_local_time, null, "measured", "The latest time you were active, in your local time.");
    add("latest_session_weekday", null, night.weekday, null, "measured", "Weekday of that latest session.");
    add(
      "latest_session_month",
      night.month,
      MONTH_NAMES[night.month - 1] ?? null,
      "month",
      "measured",
      "Month of that latest session.",
    );
  }

  return metrics;
}
