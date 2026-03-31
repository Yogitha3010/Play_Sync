const admin = require("firebase-admin");
const {
  onDocumentCreated,
  onDocumentUpdated,
} = require("firebase-functions/v2/firestore");
const { logger } = require("firebase-functions");

admin.initializeApp();

const db = admin.firestore();
const messaging = admin.messaging();

async function getUserDisplayName(userId, fallback) {
  try {
    const [profileDoc, userDoc] = await Promise.all([
      db.collection("playerProfiles").doc(userId).get(),
      db.collection("users").doc(userId).get(),
    ]);

    const profile = profileDoc.exists ? profileDoc.data() : null;
    const user = userDoc.exists ? userDoc.data() : null;

    const candidates = [
      profile?.name,
      profile?.username,
      user?.name,
      user?.username,
      fallback,
    ];

    for (const candidate of candidates) {
      if (typeof candidate === "string" && candidate.trim()) {
        return candidate.trim();
      }
    }
  } catch (error) {
    logger.error("Failed to resolve display name", { userId, error });
  }

  return fallback;
}

async function getTokensForUser(userId) {
  const userDoc = await db.collection("users").doc(userId).get();
  if (!userDoc.exists) {
    return [];
  }

  const tokens = userDoc.data()?.fcmTokens;
  if (!Array.isArray(tokens)) {
    return [];
  }

  return tokens.filter((token) => typeof token === "string" && token.trim());
}

async function removeInvalidTokens(userId, invalidTokens) {
  if (!invalidTokens.length) {
    return;
  }

  await db.collection("users").doc(userId).set(
    {
      fcmTokens: admin.firestore.FieldValue.arrayRemove(...invalidTokens),
      lastTokenUpdatedAt: new Date().toISOString(),
    },
    { merge: true }
  );
}

async function sendPushToUser({
  userId,
  title,
  body,
  data,
}) {
  const tokens = await getTokensForUser(userId);
  if (!tokens.length) {
    logger.info("No FCM tokens registered for user", { userId });
    return;
  }

  const response = await messaging.sendEachForMulticast({
    tokens,
    notification: {
      title,
      body,
    },
    data,
    android: {
      priority: "high",
      notification: {
        channelId: "play_requests",
      },
    },
    apns: {
      headers: {
        "apns-priority": "10",
      },
      payload: {
        aps: {
          sound: "default",
        },
      },
    },
  });

  const invalidTokens = [];
  response.responses.forEach((result, index) => {
    if (result.success) {
      return;
    }

    const code = result.error?.code || "";
    if (
      code === "messaging/registration-token-not-registered" ||
      code === "messaging/invalid-registration-token"
    ) {
      invalidTokens.push(tokens[index]);
    }
  });

  await removeInvalidTokens(userId, invalidTokens);
}

exports.sendPlayRequestCreatedPush = onDocumentCreated(
  {
    document: "playRequests/{requestId}",
    region: "asia-south1",
  },
  async (event) => {
    const request = event.data?.data();
    if (!request) {
      return;
    }

    const senderName = await getUserDisplayName(request.fromUserId, "A player");
    await sendPushToUser({
      userId: request.toUserId,
      title: "New play request",
      body: `${senderName} sent you a ${request.gameType} request for ${request.slotTime}.`,
      data: {
        type: "play_request_received",
        target: "requests",
        requestId: String(request.requestId || event.params.requestId),
      },
    });
  }
);

exports.sendPlayRequestUpdatedPush = onDocumentUpdated(
  {
    document: "playRequests/{requestId}",
    region: "asia-south1",
  },
  async (event) => {
    const before = event.data?.before.data();
    const after = event.data?.after.data();
    if (!before || !after) {
      return;
    }

    if (before.status === after.status) {
      return;
    }

    if (!["accepted", "rejected"].includes(after.status)) {
      return;
    }

    const receiverName = await getUserDisplayName(after.toUserId, "The player");
    const verb = after.status === "accepted" ? "accepted" : "rejected";

    await sendPushToUser({
      userId: after.fromUserId,
      title: "Play request update",
      body: `${receiverName} ${verb} your ${after.gameType} request for ${after.slotTime}.`,
      data: {
        type: `play_request_${after.status}`,
        target: "requests",
        requestId: String(after.requestId || event.params.requestId),
      },
    });
  }
);
