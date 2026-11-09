import { describe, it, expect, vi } from 'vitest';
import { handleUncaughtException, handleUnhandledRejection } from './monitoring';

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

describe('sin datos personales en los logs de errores no capturados', () => {
  const SECRET = 'ana@example.com rodilla 82.5';

  it('uncaughtException registra nombre y pila, nunca el mensaje', () => {
    const logSpy = vi.spyOn(console, 'log').mockImplementation(() => undefined);
    handleUncaughtException(new TypeError(SECRET), vi.fn() as unknown as (code: number) => never);
    const line = logSpy.mock.calls.map((c) => String(c[0])).join('\n');
    expect(line).toContain('TypeError');
    expect(line).not.toContain('ana@example.com');
    expect(line).not.toContain('rodilla');
    logSpy.mockRestore();
  });

  it('unhandledRejection no registra el mensaje ni String(reason)', () => {
    const logSpy = vi.spyOn(console, 'log').mockImplementation(() => undefined);
    handleUnhandledRejection(new Error(SECRET));
    handleUnhandledRejection(SECRET);
    const line = logSpy.mock.calls.map((c) => String(c[0])).join('\n');
    expect(line).toContain('Unhandled rejection');
    expect(line).not.toContain('ana@example.com');
    logSpy.mockRestore();
  });
});
