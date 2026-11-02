import { parsePersona } from "../../../../data/schema.ts";
import { bundleText } from "../../../../scripts/export-runs.ts";
import { computeMetrics } from "./metrics.ts";
import {
  buildPersonalRun,
  buildRunBundle,
  DEFAULT_PRIVACY,
  paletteName,
  scoreArchetypes,
  thirdTopicIsUndercut,
  type RunSource,
} from "./cards.ts";
import { deleteRun, persistRun } from "./persist.ts";

const friends = "friends\u2019";

function months() {
  return Array.from({ length: 11 }, (_, index) => ({
    month: index + 1,
    photo: `m-${String(index + 1).padStart(2, "0")}`,
  }));
}

const mayaPayloads = [
  {
    handle: "maya.lens",
    photos: ["tile-1", "tile-2", "tile-3", "tile-4", "tile-5"],
    windowLabel: "Jan 1 to Nov 15",
    copy: {
      headline: "2026 LOOKED\nGOOD ON\nYOU.",
      support: "Built from your own posts and Stories, Jan 1 to Nov 15.",
    },
  },
  {
    months: months(),
    topMonth: 8,
    topMonthPosts: 9,
    topMonthStories: 61,
    montageSeconds: 15,
    copy: {
      headline: "YOU HAD QUITE\nA YEAR.",
      support: "August was your busiest month: 9 posts, 61 Stories.",
      playLabel: "PLAY YOUR\nYEAR \u00b7 0:15",
      hubHighlight: "11 months",
      hubDetail: "Play the 15-second recap",
    },
  },
  {
    paletteName: "Midnight Camel",
    likedPosts: 1840,
    swatches: [
      { hex: "#1F2A44", pct: 31 },
      { hex: "#C8A27C", pct: 24 },
      { hex: "#8B3A3A", pct: 19 },
      { hex: "#E9E1D3", pct: 15 },
      { hex: "#4E6B4A", pct: 11 },
    ],
    copy: {
      headline: "YOUR FEED\nHAD A COLOR.",
      footnote: "% = main color in each of 1,840 liked posts",
    },
  },
  {
    topics: [
      { name: "Streetwear drops" },
      { name: "Film cameras" },
      { name: "Ceramic frogs", isUndercut: true, watched: 63 },
    ],
    copy: {
      headline: "YOUR ALGORITHM\nTHINKS YOU'RE\nINTO...",
      undercut: "63 watched. No judgment.",
    },
  },
  {
    categories: [
      ["Streetwear", 31],
      ["Food in Chicago", 22],
      ["Film photography", 18],
      ["Interior design", 12],
      ["Ceramics", 9],
    ],
    fastestRising: { name: "Ceramics", multiple: 4, since: "June" },
    reelsSent: 1206,
    copy: {
      headline: "DOWN THE\nRABBIT HOLE.",
      fastestRising: "Ceramics, 4x since June",
      sent: "And you sent 1,206 of them to friends.",
      hubDetail: "4x since June",
    },
  },
  {
    postId: "post_0719",
    photo: "main-character",
    likes: 2184,
    comments: 418,
    vsAverage: 3,
    postedAt: "2026-07-19",
    copy: {
      headline: "MAIN CHARACTER\nPOST",
      comments: "418 comments. Unhinged ones.",
      average: "That's 3x your average post.",
      posted: "Measured \u00b7 posted Jul 19",
      dateChip: "Jul 19",
      hubHighlight: "2,184 likes",
      hubDetail: "Jul 19, 3x your average",
    },
  },
  {
    storyId: "story_0314",
    photo: "story-0314",
    replies: 47,
    windowHours: 24,
    postedAt: "2026-03-14",
    copy: {
      headline: "THE STORY THAT\nBROKE THE\nGROUP CHAT.",
      storyChip: "Story \u00b7 Mar 14",
    },
  },
  {
    handles: ["dee.films", "jules.mp", "nico_k", "sam.wav", "tori.eats"],
    copy: {
      headline: "YOUR CIRCLE.",
      note: "The five accounts you showed up for most. No ranking, no scores.",
      privacy: "Want the ranked version? It lives in Privacy, off by default.",
    },
  },
  {
    latestLocalTime: "03:42",
    weekday: "Tuesday",
    month: "May",
    copy: {
      headline: "WELCOME TO\nTHE 3AM CLUB.",
      time: "3:42 AM",
      note: "A Tuesday in May. We hope it was worth it.",
    },
  },
  {
    sentence: "In June you fell into ceramics and never climbed out.",
    category: "Ceramics",
    monthly: [3, 2, 4, 3, 5, 22, 41, 58, 64, 71, 80],
    turnMonth: 6,
    copy: { headline: "PLOT\nTWIST." },
  },
  {
    copy: {
      headline: "THREE CLUES. ONE\nPERSONALITY.",
      clues: [
        "You saved 1,214 posts",
        "You posted 38 times all year",
        `You watched 96% of ${friends} Stories`,
      ],
    },
  },
  {
    primary: "curator",
    primaryScore: 70,
    secondary: "ghost",
    secondaryScore: 30,
    reasons: [
      ["1,214", "posts saved"],
      ["38", "posts all year"],
      ["96%", `of ${friends} Stories watched`],
    ],
    copy: {
      name: "THE\nCURATOR",
      side: "with a side of The Ghost",
      primaryMatch: "70% Curator match",
      secondaryMatch: "30% Ghost match",
    },
  },
  {
    identity: { archetype: "curator", stat: ["1,214", "posts saved"] },
    numbers: {
      photo: "year-card",
      stats: [["412", "Stories"], ["38", "Posts"], ["1,206", "Reels sent"], ["1,214", "Saves"]],
      topInterest: "Streetwear",
    },
    copy: { identityYear: "MY 2026", numbersTitle: "2026 IN NUMBERS" },
  },
];

async function load(key: string) {
  const file = new URL(`../../../../data/personas/${key}.json`, import.meta.url);
  return parsePersona(JSON.parse(await Deno.readTextFile(file)));
}

function profileOf(persona: { profile: { handle: string; is_teen: boolean } }) {
  return { handle: persona.profile.handle, is_teen: persona.profile.is_teen };
}

Deno.test("info sheet window and reels method come from the engine", async () => {
  const maya = await load("maya");
  const bundle = buildRunBundle(maya, { handle: maya.profile.handle, is_teen: false });
  const posts = bundle.metrics.find((metric) => metric.key === "posts");
  if (posts?.window_label !== "Jan 1 to Nov 15, 2026") throw new Error(posts?.window_label ?? "missing window");
  const reels = bundle.metrics.find((metric) => metric.key === "reels_category_share");
  if (reels?.method !== "Top 5 categories by share of your Reels watch time. Other categories: 8%.") {
    throw new Error(reels?.method ?? "missing reels method");
  }
  const card = bundle.cards.find((item) => item.type === "reelsRabbitHole");
  if (!card?.metric_keys.includes("reels_category_share")) throw new Error("reels card is missing its metric key");
  const opening = bundle.cards.find((item) => item.type === "opening");
  if (opening?.metric_keys.length !== 0) throw new Error("opening has metrics");
});

Deno.test("exported bundles match buildRunBundle", async () => {
  const maya = await load("maya");
  const jobs: [string, Awaited<ReturnType<typeof load>>, { handle: string; is_teen: boolean }][] = [
    ["maya", maya, { handle: maya.profile.handle, is_teen: false }],
    ["maya-teen", maya, { handle: maya.profile.handle, is_teen: true }],
  ];
  for (const key of ["ghost", "emerging", "established"]) {
    const persona = await load(key);
    jobs.push([key, persona, { handle: persona.profile.handle, is_teen: persona.profile.is_teen }]);
  }
  for (const [name, persona, profile] of jobs) {
    const file = await Deno.readTextFile(new URL(`../../../../ios/IGWrapped/Resources/Runs/${name}.json`, import.meta.url));
    if (file !== bundleText(persona, profile)) throw new Error(`${name}.json drifted from buildRunBundle`);
  }
});

Deno.test("maya payloads match SCHEMA section 5", async () => {
  const maya = await load("maya");
  const run = buildPersonalRun(maya, profileOf(maya));
  if (run.tier !== "full") throw new Error(`tier ${run.tier}`);
  if (run.cards.length !== 13) throw new Error(`${run.cards.length} cards`);
  if (JSON.stringify(run.copy) !== JSON.stringify({
    window: "JAN 1 TO NOV 15, 2026",
    summary: "13 cards. Replay them, remix them, share the ones you like.",
  })) throw new Error(JSON.stringify(run.copy));

  const types = [
    "opening", "yearInMemories", "feedColor", "yourAlgorithm", "reelsRabbitHole",
    "mainCharacterPost", "brokeTheGroupChat", "yourCircle", "threeAmClub",
    "plotTwist", "personalityTeaser", "personalityReveal", "shareCards",
  ];
  run.cards.forEach((card, index) => {
    const actual = JSON.stringify(card.payload);
    const expected = JSON.stringify(mayaPayloads[index]);
    if (actual !== expected) {
      throw new Error(`card ${index + 1} ${card.type}\n${actual}\n${expected}`);
    }
    if (card.type !== types[index]) throw new Error(`type ${card.type}`);
    if (card.code !== `P${String(index + 1).padStart(2, "0")}`) throw new Error(card.code);
    if (card.sort_order !== index + 1) throw new Error(`sort ${card.sort_order}`);
  });

  const chapters = run.cards.map((card) => card.chapter);
  if (chapters.join(",") !== "memories,memories,interests,interests,interests,moments,moments,people,people,identity,identity,identity,identity") {
    throw new Error(chapters.join(","));
  }
  if (run.cards[7].shareable || run.cards[7].teen_safe) throw new Error("circle is private and teen-unsafe");
  if (run.cards[8].teen_safe) throw new Error("3AM is teen-unsafe");
  if (run.cards[10].shareable) throw new Error("teaser is not shareable");
  if (/\d/.test(String(run.cards[9].payload.sentence))) throw new Error("plot sentence has a digit");
  if (JSON.stringify(run.cards[6].payload.copy).includes("47")) throw new Error("47 leaked into copy");

  if (run.scores.length !== 2) throw new Error("scores");
  if (run.scores[0].archetype !== "curator" || run.scores[0].score !== 70 || run.scores[0].rank !== 1) {
    throw new Error(JSON.stringify(run.scores[0]));
  }
  if (run.scores[1].archetype !== "ghost" || run.scores[1].score !== 30 || run.scores[1].rank !== 2) {
    throw new Error(JSON.stringify(run.scores[1]));
  }
  if (!run.scores[0].rationale.inputs.some((input) => input.key === "saves" && input.value === 1214)) {
    throw new Error("curator rationale");
  }
});

Deno.test("teen keeps 11 cards and ghost stays lite", async () => {
  const maya = await load("maya");
  const teen = await load("teen");
  const ghost = await load("ghost");
  const mayaRun = buildPersonalRun(maya, profileOf(maya));
  const teenRun = buildPersonalRun(teen, profileOf(teen));
  if (teenRun.tier !== "full" || teenRun.cards.length !== 11) throw new Error("teen count");
  if (teenRun.cards.some((card) => card.type === "yourCircle" || card.type === "threeAmClub")) {
    throw new Error("teen kept an unsafe card");
  }
  if (teenRun.copy.summary !== "11 cards. Replay them, remix them, share the ones you like.") {
    throw new Error(teenRun.copy.summary);
  }
  const opening = teenRun.cards[0].payload;
  if (opening.handle !== "maya.teen") throw new Error("teen handle");
  for (const card of teenRun.cards.slice(1)) {
    const match = mayaRun.cards.find((item) => item.type === card.type);
    if (!match || JSON.stringify(match.payload) !== JSON.stringify(card.payload)) {
      throw new Error(`teen ${card.type} drifted`);
    }
  }

  const ghostRun = buildPersonalRun(ghost, profileOf(ghost));
  if (ghostRun.tier !== "lite") throw new Error(ghostRun.tier);
  if (ghostRun.cards.length !== 1 || ghostRun.cards[0].type !== "opening") throw new Error("ghost cards");
  if (ghostRun.cards[0].payload.photos && (ghostRun.cards[0].payload.photos as unknown[]).length !== 0) {
    throw new Error("ghost photos");
  }
  if (JSON.stringify(ghostRun.cards).includes("1214") || JSON.stringify(ghostRun.cards).includes("2184")) {
    throw new Error("ghost invented a maya number");
  }
  if (!ghostRun.copy.summary.startsWith("1 card.")) throw new Error(ghostRun.copy.summary);
});

Deno.test("undercut, palette, and scores are computed", () => {
  if (!thirdTopicIsUndercut([0.91, 0.84, 0.41])) throw new Error("maya undercut");
  if (thirdTopicIsUndercut([0.9, 0.85, 0.7])) throw new Error("close topics are not an undercut");
  if (paletteName([{ hex: "#1F2A44" }, { hex: "#C8A27C" }, { hex: "#8B3A3A" }, { hex: "#E9E1D3" }, { hex: "#4E6B4A" }]) !== "Midnight Camel") {
    throw new Error("palette");
  }
  if (paletteName([{ hex: "#000000" }]) !== null) throw new Error("unknown palette");

  const source: RunSource = {
    window: { start: "2026-01-01", end: "2026-11-15", label: "Jan 1 to Nov 15" },
    totals: {
      posts: 2,
      stories: 300,
      reels_sent: 0,
      saves: 10,
      days_active: 300,
      liked_posts: 0,
      friends_stories_watched_pct: 96,
    },
    main_character_post: { id: "p", posted_at: "2026-02-01", likes: 10, comments: 1, avg_likes: 4, photo: "x" },
  };
  const scores = scoreArchetypes(computeMetrics(source, source.window));
  if (scores[0]?.archetype !== "ghost" || scores[1]?.archetype !== "archivist") {
    throw new Error(JSON.stringify(scores));
  }
});

Deno.test("privacy drops saves without changing a full year to lite", async () => {
  const maya = await load("maya");
  const run = buildPersonalRun(maya, profileOf(maya), { ...DEFAULT_PRIVACY, include_saves: false });
  if (run.tier !== "full") throw new Error("tier changed");
  if (run.metrics.some((metric) => metric.key === "saves")) throw new Error("saves metric remained");
  if (run.cards.some((card) => card.type === "personalityReveal" || card.type === "personalityTeaser")) {
    throw new Error("reveal still used the saves clue");
  }
  if (!run.cards.some((card) => card.type === "mainCharacterPost")) throw new Error("main character dropped");
  if (JSON.stringify(run.cards).includes("1,214")) throw new Error("saves number still on a card");
});

const mayaUserId = "11111111-1111-4111-8111-111111111111";

Deno.test("build-run rows insert for maya and then delete", async () => {
  const permission = await Deno.permissions.query({ name: "env" });
  if (permission.state !== "granted") return;
  const url = Deno.env.get("SUPABASE_URL") ?? "";
  const key = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
  if (!url || !key) return;
  await insertMaya(url, key);
});

async function insertMaya(url: string, key: string) {
    const maya = await load("maya");
    const run = buildPersonalRun(maya, profileOf(maya));
    const runId = await persistRun(url, key, mayaUserId, run);
    try {
      const response = await fetch(`${url}/rest/v1/cards?run_id=eq.${runId}&select=type,payload&order=sort_order`, {
        headers: { apikey: key, Authorization: `Bearer ${key}` },
      });
      if (!response.ok) throw new Error(await response.text());
      const cards = await response.json() as { type: string; payload: { copy?: { headline?: string } } }[];
      if (cards.length !== 13) throw new Error(`${cards.length} stored cards`);
      if (cards[0].payload.copy?.headline !== "2026 looked good on you.") throw new Error("stored headline");
    } finally {
      await deleteRun(url, key, mayaUserId, run.year);
    }
}
