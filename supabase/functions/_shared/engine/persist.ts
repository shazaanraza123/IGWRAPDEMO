import type { PersonalRun } from "./cards.ts";

export type PlannedRun = {
  run: Record<string, unknown>;
  metrics: Record<string, unknown>[];
  scores: Record<string, unknown>[];
  cards: Record<string, unknown>[];
};

export function planInserts(userId: string, personal: PersonalRun): PlannedRun {
  const runId = crypto.randomUUID();
  const metricRows = personal.metrics.map((metric) => ({
    id: crypto.randomUUID(),
    run_id: runId,
    key: metric.key,
    value_num: metric.value_num,
    value_text: metric.value_text,
    unit: metric.unit,
    provenance: metric.provenance,
    method: metric.method,
    window_start: metric.window_start,
    window_end: metric.window_end,
  }));
  const idsByKey = new Map<string, string[]>();
  for (const row of metricRows) {
    const key = String(row.key);
    const list = idsByKey.get(key) ?? [];
    list.push(String(row.id));
    idsByKey.set(key, list);
  }
  return {
    run: {
      id: runId,
      user_id: userId,
      year: personal.year,
      edition: personal.edition,
      period_start: personal.period_start,
      period_end: personal.period_end,
      tier: personal.tier,
      status: "ready",
      engine_version: personal.engine_version,
      generated_at: new Date().toISOString(),
      copy: personal.copy,
    },
    metrics: metricRows,
    scores: personal.scores.map((score) => ({
      run_id: runId,
      archetype: score.archetype,
      score: score.score,
      rank: score.rank,
      rationale: score.rationale,
    })),
    cards: personal.cards.map((card) => ({
      id: crypto.randomUUID(),
      run_id: runId,
      code: card.code,
      type: card.type,
      chapter: card.chapter,
      sort_order: card.sort_order,
      payload: card.payload,
      metric_ids: card.metric_keys.flatMap((key) => idsByKey.get(key) ?? []),
      shareable: card.shareable,
      teen_safe: card.teen_safe,
      hidden: card.hidden,
    })),
  };
}

export function serviceHeaders(serviceRoleKey: string, prefer: string) {
  return {
    apikey: serviceRoleKey,
    Authorization: `Bearer ${serviceRoleKey}`,
    "Content-Type": "application/json",
    Prefer: prefer,
  };
}

export async function serviceRest(url: string, serviceRoleKey: string, path: string, init: RequestInit) {
  const response = await fetch(`${url}${path}`, init);
  if (!response.ok) {
    throw new Error(`${init.method ?? "GET"} ${path} failed (${response.status}): ${await response.text()}`);
  }
  const text = await response.text();
  return text ? JSON.parse(text) : null;
}

export async function persistRun(url: string, serviceRoleKey: string, userId: string, personal: PersonalRun) {
  const base = url.replace(/\/$/, "");
  const planned = planInserts(userId, personal);
  const year = personal.year;
  await serviceRest(base, serviceRoleKey, `/rest/v1/wrapped_runs?user_id=eq.${userId}&year=eq.${year}&edition=eq.personal`, {
    method: "DELETE",
    headers: serviceHeaders(serviceRoleKey, "return=minimal"),
  });
  await serviceRest(base, serviceRoleKey, "/rest/v1/wrapped_runs", {
    method: "POST",
    headers: serviceHeaders(serviceRoleKey, "return=minimal"),
    body: JSON.stringify(planned.run),
  });
  if (planned.metrics.length > 0) {
    await serviceRest(base, serviceRoleKey, "/rest/v1/metrics", {
      method: "POST",
      headers: serviceHeaders(serviceRoleKey, "return=minimal"),
      body: JSON.stringify(planned.metrics),
    });
  }
  if (planned.scores.length > 0) {
    await serviceRest(base, serviceRoleKey, "/rest/v1/archetype_scores", {
      method: "POST",
      headers: serviceHeaders(serviceRoleKey, "return=minimal"),
      body: JSON.stringify(planned.scores),
    });
  }
  if (planned.cards.length > 0) {
    await serviceRest(base, serviceRoleKey, "/rest/v1/cards", {
      method: "POST",
      headers: serviceHeaders(serviceRoleKey, "return=minimal"),
      body: JSON.stringify(planned.cards),
    });
  }
  return String(planned.run.id);
}

export async function deleteRun(url: string, serviceRoleKey: string, userId: string, year: number) {
  const base = url.replace(/\/$/, "");
  await serviceRest(base, serviceRoleKey, `/rest/v1/wrapped_runs?user_id=eq.${userId}&year=eq.${year}&edition=eq.personal`, {
    method: "DELETE",
    headers: serviceHeaders(serviceRoleKey, "return=minimal"),
  });
}
