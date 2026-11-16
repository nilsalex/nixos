// pi provider extension: discovers models from the litellm proxy's
// pass-through catalog (tng's OpenRouter-schema /v1/models) and registers
// them under the "litellm" provider with full metadata (context window,
// output limits, reasoning support, per-million-token cost).
//
// Required environment (set by the pi wrapper):
//   LITELLM_BASE    completions endpoint, e.g. http://host.lima.internal:4000/v1
//   LITELLM_MODELS  catalog endpoint, e.g. http://.../upstream/personal/v1/models
//   LITELLM_KEY     virtual key for the bucket
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

interface TngModel {
  id: string;
  name?: string;
  context_length?: number;
  architecture?: { modality?: string };
  supported_parameters?: string[];
  top_provider?: {
    context_length?: number;
    max_completion_tokens?: number;
  };
  pricing?: Record<"prompt" | "completion" | "cache_read" | "cache_write", string | undefined>;
}

interface ChatModel {
  type: "chat";
  id: string;
  name: string;
  reasoning: boolean;
  input: ["text"];
  contextWindow: number;
  maxTokens: number;
  cost: { input: number; output: number; cacheRead: number; cacheWrite: number };
}

function toPiModel(m: TngModel): ChatModel {
  const price = (field: "prompt" | "completion" | "cache_read" | "cache_write") =>
    Number(m.pricing?.[field] ?? "0") * 1_000_000;
  return {
    type: "chat",
    id: m.id,
    name: m.name ?? m.id,
    reasoning: (m.supported_parameters ?? []).includes("reasoning"),
    input: ["text"],
    contextWindow: m.context_length ?? m.top_provider?.context_length ?? 128000,
    maxTokens: m.top_provider?.max_completion_tokens ?? 16384,
    cost: {
      input: price("prompt"),
      output: price("completion"),
      cacheRead: price("cache_read"),
      cacheWrite: price("cache_write"),
    },
  };
}

export default async function (pi: ExtensionAPI) {
  const base = process.env.LITELLM_BASE;
  const catalogUrl = process.env.LITELLM_MODELS;
  const key = process.env.LITELLM_KEY;
  if (!base || !catalogUrl || !key) return;

  async function discover(signal?: AbortSignal): Promise<ChatModel[]> {
    const res = await fetch(catalogUrl, {
      headers: { Authorization: `Bearer ${key}` },
      signal,
    });
    if (!res.ok) return [];
    const payload = (await res.json()) as { data?: TngModel[] };
    return (payload.data ?? [])
      .filter((m) => m.architecture?.modality === "text->text")
      .map(toPiModel)
      .sort((a, b) => a.id.localeCompare(b.id));
  }

  pi.registerProvider("litellm", {
    name: "LiteLLM",
    baseUrl: base,
    api: "openai-completions",
    apiKey: "$LITELLM_KEY",
    compat: { thinkingFormat: "openrouter" },
    models: await discover(),
    refreshModels: async (context) => discover(context.signal),
  });
}
