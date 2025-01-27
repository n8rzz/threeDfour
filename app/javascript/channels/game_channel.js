import consumer from "channels/consumer";

function connectToGameChannel() {
  const gameContainer = document.querySelector("[data-game-id]");

  if (!gameContainer) {
    return;
  }

  const gameId = gameContainer.dataset.gameId;

  // Return early if we're already subscribed to this game
  if (window.gameChannel && window.gameChannel.gameId === gameId) {
    return;
  }

  if (window.gameChannel) {
    window.gameChannel.unsubscribe();
  }

  window.gameChannel = consumer.subscriptions.create(
    { channel: "GameChannel", game_id: gameId },
    {
      connected() {
        console.log("Connected to game channel", gameId);
        this.gameId = gameId; // Store the gameId on the channel object
      },

      disconnected() {
        console.log("Disconnected from game channel");
      },

      received(data) {
        console.log("Received data:", data);
      },
    }
  );
}

// Connect when the page loads
document.addEventListener("turbo:load", connectToGameChannel);
// Reconnect when Turbo renders a frame
document.addEventListener("turbo:render", connectToGameChannel);
