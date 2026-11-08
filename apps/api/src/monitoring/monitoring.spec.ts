import { describe, it, expect, vi } from 'vitest';
import { handleUncaughtException } from './monitoring';

describe('handleUncaughtException', () => {
  it('registra el error y termina el proceso con código 1', () => {
    const logSpy = vi.spyOn(console, 'log').mockImplementation(() => undefined);
    const exit = vi.fn() as unknown as (code: number) => never;

    handleUncaughtException(new Error('boom'), exit);

    expect(logSpy).toHaveBeenCalled();
    expect(String(logSpy.mock.calls[0]?.[0])).toContain('Uncaught exception');
    expect(exit).toHaveBeenCalledWith(1);
    logSpy.mockRestore();
  });
});
