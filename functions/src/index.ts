/**
 * Import function triggers from their respective submodules:
 *
 * import {onCall} from "firebase-functions/v2/https";
 * import {onDocumentWritten} from "firebase-functions/v2/firestore";
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

import {onCall} from "firebase-functions/v2/https";
import * as logger from "firebase-functions/logger";

export const helloWorld = onCall((request: any) => {
  logger.info("Hello logs!", {structuredData: true});
  return { message: "Hello from Firebase!" };
});

export const helloWorldStream = onCall(async (request) => {
  logger.info("Stream function called");

  const delay = (ms: number) => new Promise((res) => setTimeout(res, ms));

  const chunks = ["chunk 1", "chunk 2", "chunk 3"];
  const messages: string[] = [];

  for (const chunk of chunks) {
    await delay(5000); // 5-second delay per chunk
    messages.push(chunk);
    logger.info("Sent chunk:", chunk);
  }

  return { messages }; // send all at once
});

export const tinyChunkStream = onCall(async () => {
  logger.info("tinyChunkStream called");

  const message = "Hello iOS streaming!";
  const delay = (ms: number) => new Promise((res) => setTimeout(res, ms));
  const chunks: string[] = [];

  for (let i = 0; i < message.length; i += 2) { // 2 chars per chunk
    const chunk = message.slice(i, i + 2);
    await delay(5000); // 5 second delay per chunk
    chunks.push(chunk);
    logger.info("Sent chunk:", chunk);
  }

  return { chunks }; // all chunks are returned together by callable
});

export const testStreamingCallable = onCall(async (data) => {
    // Safely get parameters
    const count = data?.data?.count ?? 5;
    const delay = data?.data?.delay ?? 500; // ms
  
    logger.info("Streaming function called", { count, delay });
  
    const results: string[] = [];
    const sleep = (ms: number) => new Promise((res) => setTimeout(res, ms));
  
    for (let i = 0; i < count; i++) {
      await sleep(delay);
      const chunk = `chunk_${i}`;
      results.push(chunk);
      logger.info("Sent chunk", chunk);
    }
  
    return { results };
  });
  
