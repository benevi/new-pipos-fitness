import { AIResponseNormalizerService } from './ai-response-normalizer';

describe('AIResponseNormalizerService', () => {
  let normalizer: AIResponseNormalizerService;

  beforeEach(() => {
    normalizer = new AIResponseNormalizerService();
  });

  it('returns safe fallback for null input', () => {
    const result = normalizer.normalize(null);
    expect(result.responseType).toBe('answer');
    expect(result.content).toContain('not confident');
  });

  it('returns safe fallback for empty object', () => {
    const result = normalizer.normalize({});
    expect(result.responseType).toBe('answer');
    expect(result.content).toContain('not confident');
  });

  it('returns safe fallback for invalid responseType', () => {
    const result = normalizer.normalize({ responseType: 'invalid', content: 'hi' });
    expect(result.responseType).toBe('answer');
    expect(result.content).toContain('not confident');
  });

  it('returns safe fallback for empty content', () => {
    const result = normalizer.normalize({ responseType: 'answer', content: '' });
    expect(result.responseType).toBe('answer');
    expect(result.content).toContain('not confident');
  });

  it('passes through valid answer response', () => {
    const result = normalizer.normalize({
      responseType: 'answer',
      content: 'Here is your answer.',
    });
    expect(result).toEqual({
      responseType: 'answer',
      content: 'Here is your answer.',
    });
  });

  it('passes through valid explanation response', () => {
    const result = normalizer.normalize({
      responseType: 'explanation',
      content: 'Because of this.',
    });
    expect(result).toEqual({
      responseType: 'explanation',
      content: 'Because of this.',
    });
  });

  it('strips unexpected extra fields', () => {
    const result = normalizer.normalize({
      responseType: 'answer',
      content: 'clean',
      _internal: 'secret',
      debugInfo: {},
    });
    expect(result).toEqual({
      responseType: 'answer',
      content: 'clean',
    });
    expect((result as Record<string, unknown>)._internal).toBeUndefined();
  });

  it('returns fallback for proposal without proposal object', () => {
    const result = normalizer.normalize({
      responseType: 'proposal',
      content: 'swap something',
    });
    expect(result.responseType).toBe('answer');
    expect(result.content).toContain('not confident');
  });

  it('returns fallback for non-object input', () => {
    expect(normalizer.normalize('hello').responseType).toBe('answer');
    expect(normalizer.normalize(42).responseType).toBe('answer');
    expect(normalizer.normalize(undefined).responseType).toBe('answer');
  });
});
