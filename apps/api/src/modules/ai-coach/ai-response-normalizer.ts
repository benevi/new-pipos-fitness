import { Injectable } from '@nestjs/common';
import { AIResponseSchema } from '@pipos/contracts';
import type { AIResponse } from '@pipos/contracts';

const SAFE_FALLBACK: AIResponse = {
  responseType: 'answer',
  content:
    "I'm not confident about that suggestion. Please consult your plan directly.",
};

@Injectable()
export class AIResponseNormalizerService {
  normalize(raw: unknown): AIResponse {
    if (raw == null || typeof raw !== 'object') {
      return { ...SAFE_FALLBACK };
    }

    const candidate = raw as Record<string, unknown>;

    if (!candidate.responseType || typeof candidate.content !== 'string' || candidate.content.length === 0) {
      return { ...SAFE_FALLBACK };
    }

    const stripped: Record<string, unknown> = {
      responseType: candidate.responseType,
      content: candidate.content,
    };
    if (candidate.proposal !== undefined) {
      stripped.proposal = candidate.proposal;
    }

    const result = AIResponseSchema.safeParse(stripped);
    if (!result.success) {
      return { ...SAFE_FALLBACK };
    }

    return result.data;
  }
}
