import consumer from "channels/consumer";

function connectToGameChannel() {
  console.log("connectToGameChannel");

  const gameContainer = document.querySelector("[data-game-id]");

  if (!gameContainer) {
    return;
  }

  const gameId = gameContainer.dataset.gameId;

  if (window.gameChannel) {
    window.gameChannel.unsubscribe();
  }

  window.gameChannel = consumer.subscriptions.create(
    { channel: "GameChannel", game_id: gameId },
    {
      connected() {
        console.log("Connected to game channel", gameId);
      },

      disconnected() {
        console.log("Disconnected from game channel");
      },

      received(data) {
        console.log("Received data:", data);
        // Handle incoming game updates here
      },
    }
  );
}

// Connect when the page loads
document.addEventListener("turbo:load", connectToGameChannel);
// Reconnect when Turbo renders a frame
document.addEventListener("turbo:render", connectToGameChannel);
