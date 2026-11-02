import { computeMetrics, monthName, type Metric, type MetricSource, type MetricWindow } from "./metrics.ts";

export type ProvenanceScore = {
  archetype: string;
  score: number;
  rank: number;
  rationale: { inputs: { key: string; value: number }[] };
};

export type ArchetypeScore = ProvenanceScore;

export type CardType =
  | "opening"
  | "yearInMemories"
  | "feedColor"
  | "yourAlgorithm"
  | "reelsRabbitHole"
  | "mainCharacterPost"
  | "brokeTheGroupChat"
  | "yourCircle"
  | "threeAmClub"
  | "plotTwist"
  | "personalityTeaser"
  | "personalityReveal"
  | "shareCards";

export type Chapter = "memories" | "interests" | "moments" | "people" | "identity";

export type EngineCard = {
  code: string;
  type: CardType;
  chapter: Chapter;
  sort_order: number;
  payload: Record<string, unknown>;
  metric_keys: string[];
  shareable: boolean;
  teen_safe: boolean;
  hidden: boolean;
  window_start: string;
  window_end: string;
};

export type RunProfile = {
  handle: string;
  is_teen: boolean;
};

export type PrivacySettings = {
  include_dm_stats: boolean;
  include_watch_history: boolean;
  include_saves: boolean;
  allow_together: boolean;
  ranked_circle: boolean;
  hide_usernames_on_share: boolean;
  autoplay: boolean;
};

export type RunSource = Omit<MetricSource, "monthly" | "main_character_post" | "most_replied_story"> & {
  window: MetricWindow & { label: string };
  opening_photos?: string[];
  monthly?: { month: number; posts: number; stories: number; photo?: string }[];
  main_character_post?: {
    id: string;
    posted_at: string;
    likes: number;
    comments: number;
    avg_likes: number;
    photo?: string;
  };
  most_replied_story?: { id: string; photo?: string; posted_at: string; replies_24h: number };
  share_cards?: { numbers_photo?: string };
};

export const DEFAULT_PRIVACY: PrivacySettings = {
  include_dm_stats: true,
  include_watch_history: true,
  include_saves: true,
  allow_together: true,
  ranked_circle: false,
  hide_usernames_on_share: true,
  autoplay: true,
};

const MONTAGE_SECONDS = 15;
const STORY_REPLY_HOURS = 24;
export const UNDERCUT_GAP = 0.3;

const DOT = "\u00b7";
const FRIENDS = "friends\u2019";

const ARCHETYPE_ORDER = [
  "curator",
  "ghost",
  "reel_dealer",
  "main_character",
  "close_friend",
  "trendspotter",
  "social_butterfly",
  "archivist",
] as const;

const CHAPTER: Record<CardType, Chapter> = {
  opening: "memories",
  yearInMemories: "memories",
  feedColor: "interests",
  yourAlgorithm: "interests",
  reelsRabbitHole: "interests",
  mainCharacterPost: "moments",
  brokeTheGroupChat: "moments",
  yourCircle: "people",
  threeAmClub: "people",
  plotTwist: "identity",
  personalityTeaser: "identity",
  personalityReveal: "identity",
  shareCards: "identity",
};

const LITE = new Set<CardType>(["opening", "yearInMemories", "personalityReveal", "shareCards"]);

const SHAREABLE: Record<CardType, boolean> = {
  opening: true,
  yearInMemories: true,
  feedColor: true,
  yourAlgorithm: true,
  reelsRabbitHole: true,
  mainCharacterPost: true,
  brokeTheGroupChat: true,
  yourCircle: false,
  threeAmClub: true,
  plotTwist: true,
  personalityTeaser: false,
  personalityReveal: true,
  shareCards: true,
};

const TEEN_SAFE: Record<CardType, boolean> = {
  opening: true,
  yearInMemories: true,
  feedColor: true,
  yourAlgorithm: true,
  reelsRabbitHole: true,
  mainCharacterPost: true,
  brokeTheGroupChat: true,
  yourCircle: false,
  threeAmClub: false,
  plotTwist: true,
  personalityTeaser: true,
  personalityReveal: true,
  shareCards: true,
};

const WATCH_KEYS = new Set([
  "friends_stories_watched_pct",
  "explore_topic",
  "explore_topic_watched",
  "reels_category_share",
  "top_reels_category",
  "fastest_rising_multiple",
  "fastest_rising_since_month",
  "plot_turn_month",
  "reels_sent",
]);

const PALETTES = [
  { name: "Midnight Camel", hexes: ["#1F2A44", "#C8A27C", "#8B3A3A", "#E9E1D3", "#4E6B4A"] },
];

const SHORT_MONTHS = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];

function clamp(value: number) {
  return Math.max(0, Math.min(100, Math.round(value)));
}

function formatCount(value: number) {
  return new Intl.NumberFormat("en-US").format(value);
}

function formatMultiple(value: number) {
  return `${value}x`;
}

function formatClock(value: string) {
  const [hourText, minuteText] = value.split(":");
  const hour = Number(hourText);
  const minute = Number(minuteText);
  const suffix = hour >= 12 ? "PM" : "AM";
  const shown = hour % 12 === 0 ? 12 : hour % 12;
  return `${shown}:${String(minute).padStart(2, "0")} ${suffix}`;
}

function formatShortDate(iso: string) {
  const [, monthText, dayText] = iso.split("-");
  return `${SHORT_MONTHS[Number(monthText) - 1]} ${Number(dayText)}`;
}

function formatDuration(seconds: number) {
  const minutes = Math.floor(seconds / 60);
  const rest = seconds % 60;
  return `${minutes}:${String(rest).padStart(2, "0")}`;
}

function rows(metrics: Metric[], key: string) {
  return metrics.filter((metric) => metric.key === key);
}

function one(metrics: Metric[], key: string) {
  return rows(metrics, key)[0];
}

function num(metrics: Metric[], key: string) {
  const metric = one(metrics, key);
  return metric?.value_num ?? null;
}

function text(metrics: Metric[], key: string) {
  return one(metrics, key)?.value_text ?? null;
}

export function applyPrivacy(metrics: Metric[], privacy: PrivacySettings) {
  return metrics.filter((metric) => {
    if (!privacy.include_saves && metric.key === "saves") return false;
    if (!privacy.include_watch_history && WATCH_KEYS.has(metric.key)) return false;
    if (!privacy.include_dm_stats && (metric.key.includes("dm") || metric.unit === "dms")) return false;
    return true;
  });
}

export function paletteName(swatches: { hex: string }[]) {
  const key = swatches.map((swatch) => swatch.hex.toUpperCase()).join(",");
  return PALETTES.find((palette) => palette.hexes.join(",") === key)?.name ?? null;
}

export function thirdTopicIsUndercut(scores: number[]) {
  if (scores.length < 3) return false;
  return scores[2] <= Math.min(scores[0], scores[1]) - UNDERCUT_GAP;
}

function archetypeLabel(key: string) {
  return key.split("_").map((part) => part.charAt(0).toUpperCase() + part.slice(1)).join(" ");
}

function reasonColumns(metrics: Metric[]): [string, string][] | null {
  const saves = num(metrics, "saves");
  const posts = num(metrics, "posts");
  const watched = num(metrics, "friends_stories_watched_pct");
  if (saves === null || posts === null || watched === null) return null;
  return [
    [formatCount(saves), "posts saved"],
    [formatCount(posts), "posts all year"],
    [`${formatCount(watched)}%`, `of ${FRIENDS} Stories watched`],
  ];
}

function leadStat(archetype: string, metrics: Metric[]) {
  const reasons = reasonColumns(metrics);
  if (!reasons) return null;
  if (archetype === "ghost") return reasons[2];
  if (archetype === "main_character" || archetype === "archivist") return reasons[1];
  return reasons[0];
}

export function scoreArchetypes(metrics: Metric[]): ArchetypeScore[] {
  const posts = num(metrics, "posts");
  const saves = num(metrics, "saves");
  const stories = num(metrics, "stories");
  const days = num(metrics, "days_active");
  const watched = num(metrics, "friends_stories_watched_pct");
  const vsAverage = num(metrics, "main_post_vs_average");
  const multiple = num(metrics, "fastest_rising_multiple");
  const scored: ArchetypeScore[] = [];

  if (saves !== null && posts !== null && saves + 14 * posts > 0) {
    scored.push({
      archetype: "curator",
      score: clamp(100 * saves / (saves + 14 * posts)),
      rank: 0,
      rationale: { inputs: [{ key: "saves", value: saves }, { key: "posts", value: posts }] },
    });
  }
  if (watched !== null && posts !== null && saves !== null && saves > 0) {
    scored.push({
      archetype: "ghost",
      score: clamp(10 * watched * posts / saves),
      rank: 0,
      rationale: {
        inputs: [
          { key: "friends_stories_watched_pct", value: watched },
          { key: "posts", value: posts },
          { key: "saves", value: saves },
        ],
      },
    });
  }
  if (posts !== null && vsAverage !== null) {
    scored.push({
      archetype: "main_character",
      score: clamp(100 * Math.min(1, posts / 100) * Math.min(1, vsAverage / 5)),
      rank: 0,
      rationale: {
        inputs: [{ key: "posts", value: posts }, { key: "main_post_vs_average", value: vsAverage }],
      },
    });
  }
  if (multiple !== null) {
    scored.push({
      archetype: "trendspotter",
      score: clamp((multiple - 1) * 5),
      rank: 0,
      rationale: { inputs: [{ key: "fastest_rising_multiple", value: multiple }] },
    });
  }
  if (stories !== null && days !== null && days > 0 && posts !== null) {
    const daily = Math.min(1, stories / days);
    const barely = Math.max(0, 1 - posts / 30);
    const score = clamp(100 * daily * barely);
    if (score > 0) {
      scored.push({
        archetype: "archivist",
        score,
        rank: 0,
        rationale: {
          inputs: [
            { key: "stories", value: stories },
            { key: "days_active", value: days },
            { key: "posts", value: posts },
          ],
        },
      });
    }
  }

  return scored
    .filter((item) => item.score > 0)
    .sort((a, b) => {
      if (b.score !== a.score) return b.score - a.score;
      return ARCHETYPE_ORDER.indexOf(a.archetype as typeof ARCHETYPE_ORDER[number]) -
        ARCHETYPE_ORDER.indexOf(b.archetype as typeof ARCHETYPE_ORDER[number]);
    })
    .slice(0, 2)
    .map((item, index) => ({ ...item, rank: index + 1 }));
}

export function renderCopy(card: EngineCard, metrics: Metric[]) {
  const year = card.window_start.slice(0, 4);
  switch (card.type) {
    case "opening":
      return {
        headline: `${year} LOOKED\nGOOD ON\nYOU.`,
        support: `Built from your own posts and Stories, ${card.payload.windowLabel}.`,
      };
    case "yearInMemories": {
      const month = text(metrics, "top_month");
      const posts = num(metrics, "top_month_posts");
      const stories = num(metrics, "top_month_stories");
      const covered = num(metrics, "months_covered");
      if (month === null || posts === null || stories === null || covered === null) return undefined;
      const coveredLabel = covered === 1 ? "month" : "months";
      return {
        headline: "YOU HAD QUITE\nA YEAR.",
        support: `${month} was your busiest month: ${formatCount(posts)} posts, ${formatCount(stories)} Stories.`,
        playLabel: `PLAY YOUR\nYEAR ${DOT} ${formatDuration(MONTAGE_SECONDS)}`,
        hubHighlight: `${formatCount(covered)} ${coveredLabel}`,
        hubDetail: `Play the ${MONTAGE_SECONDS}-second recap`,
      };
    }
    case "feedColor": {
      const liked = num(metrics, "liked_posts");
      if (liked === null) return undefined;
      return {
        headline: "YOUR FEED\nHAD A COLOR.",
        footnote: `% = main color in each of ${formatCount(liked)} liked posts`,
      };
    }
    case "yourAlgorithm": {
      const topics = card.payload.topics as { name: string; isUndercut?: boolean }[];
      const undercut = topics.find((topic) => topic.isUndercut);
      if (!undercut) return undefined;
      const watched = rows(metrics, "explore_topic_watched").find((metric) => metric.value_text === undercut.name);
      if (watched?.value_num == null) return undefined;
      return {
        headline: "YOUR ALGORITHM\nTHINKS YOU'RE\nINTO...",
        undercut: `${formatCount(watched.value_num)} watched. No judgment.`,
      };
    }
    case "reelsRabbitHole": {
      const rising = card.payload.fastestRising as { name: string; multiple: number; since: string };
      const sent = num(metrics, "reels_sent");
      if (sent === null) return undefined;
      const pace = `${rising.name}, ${formatMultiple(rising.multiple)} since ${rising.since}`;
      return {
        headline: "DOWN THE\nRABBIT HOLE.",
        fastestRising: pace,
        sent: `And you sent ${formatCount(sent)} of them to friends.`,
        hubDetail: `${formatMultiple(rising.multiple)} since ${rising.since}`,
      };
    }
    case "mainCharacterPost": {
      const comments = num(metrics, "main_post_comments");
      const vsAverage = num(metrics, "main_post_vs_average");
      const likes = num(metrics, "main_post_likes");
      const postedAt = text(metrics, "main_post_posted_at");
      if (comments === null || vsAverage === null || likes === null || postedAt === null) return undefined;
      const when = formatShortDate(postedAt);
      return {
        headline: "MAIN CHARACTER\nPOST",
        comments: `${formatCount(comments)} comments. Unhinged ones.`,
        average: `That's ${formatMultiple(vsAverage)} your average post.`,
        posted: `Measured ${DOT} posted ${when}`,
        dateChip: when,
        hubHighlight: `${formatCount(likes)} likes`,
        hubDetail: `${when}, ${formatMultiple(vsAverage)} your average`,
      };
    }
    case "brokeTheGroupChat": {
      const postedAt = text(metrics, "story_replies_24h") ? (card.payload.postedAt as string) : null;
      if (!postedAt) return undefined;
      return {
        headline: "THE STORY THAT\nBROKE THE\nGROUP CHAT.",
        storyChip: `Story ${DOT} ${formatShortDate(postedAt)}`,
      };
    }
    case "threeAmClub": {
      const time = text(metrics, "latest_local_time");
      if (!time) return undefined;
      return {
        headline: "WELCOME TO\nTHE 3AM CLUB.",
        time: formatClock(time),
        note: `A ${card.payload.weekday} in ${card.payload.month}. We hope it was worth it.`,
      };
    }
    case "personalityTeaser": {
      const reasons = reasonColumns(metrics);
      if (!reasons) return undefined;
      const [saves, posts, watched] = reasons;
      return {
        headline: "THREE CLUES. ONE\nPERSONALITY.",
        clues: [
          `You saved ${saves[0]} posts`,
          `You posted ${posts[0]} times all year`,
          `You watched ${watched[0]} of ${FRIENDS} Stories`,
        ],
      };
    }
    case "personalityReveal": {
      const primary = card.payload.primary as string;
      const secondary = card.payload.secondary as string;
      return {
        name: `THE\n${archetypeLabel(primary).toUpperCase()}`,
        side: `with a side of The ${archetypeLabel(secondary)}`,
        primaryMatch: `${card.payload.primaryScore}% ${archetypeLabel(primary)} match`,
        secondaryMatch: `${card.payload.secondaryScore}% ${archetypeLabel(secondary)} match`,
      };
    }
    case "shareCards":
      return { identityYear: `MY ${year}`, numbersTitle: `${year} IN NUMBERS` };
    case "yourCircle":
      return {
        headline: "YOUR CIRCLE.",
        note: "The five accounts you showed up for most. No ranking, no scores.",
        privacy: "Want the ranked version? It lives in Privacy, off by default.",
      };
    case "plotTwist":
      return { headline: "PLOT\nTWIST." };
    default:
      return undefined;
  }
}

function blank(
  type: CardType,
  catalogNumber: number,
  payload: Record<string, unknown>,
  metricKeys: string[],
  window: MetricWindow,
): EngineCard {
  return {
    code: `P${String(catalogNumber).padStart(2, "0")}`,
    type,
    chapter: CHAPTER[type],
    sort_order: catalogNumber,
    payload,
    metric_keys: metricKeys,
    shareable: SHAREABLE[type],
    teen_safe: TEEN_SAFE[type],
    hidden: false,
    window_start: window.start,
    window_end: window.end,
  };
}

export function selectCards(
  metrics: Metric[],
  scores: ArchetypeScore[],
  profile: RunProfile,
  privacy: PrivacySettings,
  context: { tier: "full" | "lite"; source: RunSource },
) {
  const visible = applyPrivacy(metrics, privacy);
  const source = context.source;
  const window = source.window;
  const drafts: (EngineCard | null)[] = [];

  drafts.push(profile.handle
    ? blank("opening", 1, {
      handle: profile.handle,
      photos: source.opening_photos ?? [],
      windowLabel: window.label,
    }, [], window)
    : null);

  const monthRows = rows(visible, "monthly_posts")
    .map((metric) => Number(metric.value_text))
    .sort((a, b) => a - b);
  const months = monthRows.map((month) => {
    const photo = source.monthly?.find((item) => item.month === month)?.photo;
    return photo ? { month, photo } : null;
  });
  if (
    months.length > 0 &&
    months.every((month) => month !== null) &&
    num(visible, "top_month") !== null
  ) {
    drafts.push(blank("yearInMemories", 2, {
      months,
      topMonth: num(visible, "top_month"),
      topMonthPosts: num(visible, "top_month_posts"),
      topMonthStories: num(visible, "top_month_stories"),
      montageSeconds: MONTAGE_SECONDS,
    }, ["monthly_posts", "monthly_stories", "top_month", "top_month_posts", "top_month_stories", "months_covered"], window));
  } else {
    drafts.push(null);
  }

  const swatches = rows(visible, "feed_swatch").map((metric) => ({
    hex: metric.value_text ?? "",
    pct: metric.value_num ?? 0,
  }));
  const palette = paletteName(swatches);
  if (swatches.length > 0 && palette && num(visible, "liked_posts") !== null) {
    drafts.push(blank("feedColor", 3, {
      paletteName: palette,
      likedPosts: num(visible, "liked_posts"),
      swatches,
    }, ["liked_posts", "feed_swatch"], window));
  } else {
    drafts.push(null);
  }

  const topics = rows(visible, "explore_topic").map((metric) => ({
    name: metric.value_text ?? "",
    score: metric.value_num ?? 0,
  }));
  if (topics.length > 0) {
    const undercut = thirdTopicIsUndercut(topics.map((topic) => topic.score));
    const watchedRow = rows(visible, "explore_topic_watched");
    drafts.push(blank("yourAlgorithm", 4, {
      topics: topics.map((topic, index) => {
        const watched = watchedRow.find((metric) => metric.value_text === topic.name)?.value_num;
        if (index === 2 && undercut && watched !== undefined && watched !== null) {
          return { name: topic.name, isUndercut: true, watched };
        }
        return { name: topic.name };
      }),
    }, ["explore_topic", "explore_topic_watched"], window));
  } else {
    drafts.push(null);
  }

  const categories = rows(visible, "reels_category_share").map((metric) => [metric.value_text, metric.value_num]);
  const sinceMonth = num(visible, "fastest_rising_since_month");
  const sinceName = sinceMonth === null ? null : monthName(sinceMonth);
  if (
    categories.length > 0 &&
    num(visible, "reels_sent") !== null &&
    text(visible, "fastest_rising_multiple") &&
    num(visible, "fastest_rising_multiple") !== null &&
    sinceName
  ) {
    drafts.push(blank("reelsRabbitHole", 5, {
      categories,
      fastestRising: {
        name: text(visible, "fastest_rising_multiple"),
        multiple: num(visible, "fastest_rising_multiple"),
        since: sinceName,
      },
      reelsSent: num(visible, "reels_sent"),
    }, ["reels_category_share", "fastest_rising_multiple", "fastest_rising_since_month", "reels_sent", "top_reels_category"], window));
  } else {
    drafts.push(null);
  }

  const postPhoto = source.main_character_post?.photo;
  if (
    postPhoto &&
    text(visible, "main_post_likes") &&
    num(visible, "main_post_likes") !== null &&
    num(visible, "main_post_comments") !== null &&
    num(visible, "main_post_vs_average") !== null &&
    text(visible, "main_post_posted_at")
  ) {
    drafts.push(blank("mainCharacterPost", 6, {
      postId: text(visible, "main_post_likes"),
      photo: postPhoto,
      likes: num(visible, "main_post_likes"),
      comments: num(visible, "main_post_comments"),
      vsAverage: num(visible, "main_post_vs_average"),
      postedAt: text(visible, "main_post_posted_at"),
    }, ["main_post_likes", "main_post_comments", "main_post_avg_likes", "main_post_vs_average", "main_post_posted_at"], window));
  } else {
    drafts.push(null);
  }

  const storyPhoto = source.most_replied_story?.photo;
  if (storyPhoto && text(visible, "story_replies_24h") && num(visible, "story_replies_24h") !== null) {
    const postedAt = source.most_replied_story?.posted_at;
    if (postedAt) {
      drafts.push(blank("brokeTheGroupChat", 7, {
        storyId: text(visible, "story_replies_24h"),
        photo: storyPhoto,
        replies: num(visible, "story_replies_24h"),
        windowHours: STORY_REPLY_HOURS,
        postedAt,
      }, ["story_replies_24h"], window));
    } else {
      drafts.push(null);
    }
  } else {
    drafts.push(null);
  }

  const handles = rows(visible, "circle_member").map((metric) => metric.value_text ?? "").filter((handle) => handle.length > 0)
    .sort((a, b) => a.localeCompare(b));
  drafts.push(handles.length > 0 ? blank("yourCircle", 8, { handles }, ["circle_member"], window) : null);

  if (text(visible, "latest_local_time") && text(visible, "latest_session_weekday") && text(visible, "latest_session_month")) {
    drafts.push(blank("threeAmClub", 9, {
      latestLocalTime: text(visible, "latest_local_time"),
      weekday: text(visible, "latest_session_weekday"),
      month: text(visible, "latest_session_month"),
    }, ["latest_local_time", "latest_session_weekday", "latest_session_month"], window));
  } else {
    drafts.push(null);
  }

  const series = rows(visible, "ceramics_monthly")
    .map((metric) => ({ month: Number(metric.value_text), value: metric.value_num ?? 0 }))
    .sort((a, b) => a.month - b.month);
  const category = text(visible, "plot_category");
  const turn = num(visible, "plot_turn_month");
  const turnLabel = text(visible, "plot_turn_month");
  if (series.length > 0 && category && turn !== null && turnLabel) {
    drafts.push(blank("plotTwist", 10, {
      sentence: `In ${turnLabel} you fell into ${category.toLowerCase()} and never climbed out.`,
      category,
      monthly: series.map((item) => item.value),
      turnMonth: turn,
    }, ["ceramics_monthly", "plot_category", "plot_turn_month"], window));
  } else {
    drafts.push(null);
  }

  drafts.push(reasonColumns(visible)
    ? blank("personalityTeaser", 11, {}, ["saves", "posts", "friends_stories_watched_pct"], window)
    : null);

  const reasons = reasonColumns(visible);
  if (reasons && scores.length >= 2) {
    drafts.push(blank("personalityReveal", 12, {
      primary: scores[0].archetype,
      primaryScore: scores[0].score,
      secondary: scores[1].archetype,
      secondaryScore: scores[1].score,
      reasons,
    }, ["saves", "posts", "friends_stories_watched_pct"], window));
  } else {
    drafts.push(null);
  }

  const stories = num(visible, "stories");
  const posts = num(visible, "posts");
  const reels = num(visible, "reels_sent");
  const saves = num(visible, "saves");
  const interest = text(visible, "top_reels_category");
  const photo = source.share_cards?.numbers_photo;
  const stat = scores[0] ? leadStat(scores[0].archetype, visible) : null;
  if (scores[0] && stat && stories !== null && posts !== null && reels !== null && saves !== null && interest && photo) {
    drafts.push(blank("shareCards", 13, {
      identity: { archetype: scores[0].archetype, stat },
      numbers: {
        photo,
        stats: [
          [formatCount(stories), "Stories"],
          [formatCount(posts), "Posts"],
          [formatCount(reels), "Reels sent"],
          [formatCount(saves), "Saves"],
        ],
        topInterest: interest,
      },
    }, ["stories", "posts", "reels_sent", "saves", "top_reels_category"], window));
  } else {
    drafts.push(null);
  }

  let cards = drafts.filter((item): item is EngineCard => item !== null);
  if (context.tier === "lite") cards = cards.filter((item) => LITE.has(item.type));
  if (profile.is_teen) cards = cards.filter((item) => item.teen_safe);
  return cards.map((item, index) => {
    const ordered = { ...item, sort_order: index + 1 };
    const copy = renderCopy(ordered, visible);
    if (!copy) return ordered;
    return { ...ordered, payload: { ...ordered.payload, copy } };
  });
}

export function hasYearCounts(metrics: Metric[]) {
  return num(metrics, "posts") !== null && num(metrics, "stories") !== null && num(metrics, "saves") !== null;
}

export function renderRunCopy(window: { start: string; label: string }, cardCount: number) {
  const year = window.start.slice(0, 4);
  const noun = cardCount === 1 ? "card" : "cards";
  return {
    window: `${window.label.toUpperCase()}, ${year}`,
    summary: `${cardCount} ${noun}. Replay them, remix them, share the ones you like.`,
  };
}

export type PersonalRun = {
  year: number;
  edition: "personal";
  tier: "full" | "lite";
  period_start: string;
  period_end: string;
  engine_version: string;
  copy: { window: string; summary: string };
  metrics: Metric[];
  scores: ArchetypeScore[];
  cards: EngineCard[];
};

export type RunBundle = {
  run: {
    year: number;
    edition: "personal";
    period_start: string;
    period_end: string;
    tier: "full" | "lite";
    status: "ready";
    engine_version: string;
    copy: { window: string; summary: string };
  };
  metrics: Metric[];
  archetypes: ArchetypeScore[];
  cards: {
    code: string;
    type: CardType;
    chapter: Chapter;
    sort_order: number;
    payload: Record<string, unknown>;
    shareable: boolean;
    teen_safe: boolean;
    hidden: boolean;
  }[];
};

/// The JSON shipped in the app. Same cards, metrics, and scores `build-run` persists, without random ids.
export function buildRunBundle(source: RunSource, profile: RunProfile, privacy: PrivacySettings = DEFAULT_PRIVACY): RunBundle {
  const personal = buildPersonalRun(source, profile, privacy);
  return {
    run: {
      year: personal.year,
      edition: personal.edition,
      period_start: personal.period_start,
      period_end: personal.period_end,
      tier: personal.tier,
      status: "ready",
      engine_version: personal.engine_version,
      copy: personal.copy,
    },
    metrics: personal.metrics,
    archetypes: personal.scores,
    cards: personal.cards.map((card) => ({
      code: card.code,
      type: card.type,
      chapter: card.chapter,
      sort_order: card.sort_order,
      payload: card.payload,
      shareable: card.shareable,
      teen_safe: card.teen_safe,
      hidden: card.hidden,
    })),
  };
}

export function buildPersonalRun(source: RunSource, profile: RunProfile, privacy: PrivacySettings = DEFAULT_PRIVACY): PersonalRun {
  const metrics = computeMetrics(source, source.window);
  const tier = hasYearCounts(metrics) ? "full" : "lite";
  const visible = applyPrivacy(metrics, privacy);
  const scores = scoreArchetypes(visible);
  const cards = selectCards(metrics, scores, profile, privacy, { tier, source });
  return {
    year: Number(source.window.start.slice(0, 4)),
    edition: "personal",
    tier,
    period_start: source.window.start,
    period_end: source.window.end,
    engine_version: "1",
    copy: renderRunCopy(source.window, cards.length),
    metrics: visible,
    scores,
    cards,
  };
}
