import { Queue, Worker } from 'bullmq';
import IORedis from 'ioredis';

// Default import is not typed as constructable under NodeNext; cast so tsc accepts new IORedis()
// eslint-disable-next-line @typescript-eslint/no-explicit-any
const connection = new (IORedis as any)(process.env.REDIS_URL ?? 'redis://localhost:6379', {
  maxRetriesPerRequest: null,
});

const queueName = 'pipos:placeholder';

const queue = new Queue(queueName, { connection });

const worker = new Worker(
  queueName,
  async (job) => {
    // No se registra job.data: puede contener datos personales/de salud. Sólo el id.
    console.log(`Processing job ${job.id}`);
    return { processed: true, jobId: job.id };
  },
  { connection },
);

worker.on('completed', (job) => {
  console.log(`Job ${job.id} completed`);
});

worker.on('failed', (job, err) => {
  console.error(`Job ${job?.id} failed: ${err.message}`);
});

async function shutdown() {
  await worker.close();
  await queue.close();
  connection.disconnect();
  process.exit(0);
}

process.on('SIGTERM', shutdown);
process.on('SIGINT', shutdown);

console.log('Worker started. Queue:', queueName);
