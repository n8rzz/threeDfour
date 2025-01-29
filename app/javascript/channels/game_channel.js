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
        console.log("Received game channel data:", data);

        if (data.type === "move") {
          if (data.status === "success") {
            console.log("Move successful:", data.move);

            // Update turn indicators
            document
              .querySelectorAll("[data-player-id]")
              .forEach((playerDiv) => {
                const playerId = parseInt(playerDiv.dataset.playerId);
                const turnIndicator = playerDiv.querySelector(".bg-blue-50");

                if (playerId === data.current_turn_id) {
                  if (!turnIndicator) {
                    const indicator = document.createElement("span");
                    indicator.className =
                      "inline-flex items-center rounded-md bg-blue-50 px-2 py-1 text-xs font-medium text-blue-700 ring-1 ring-inset ring-blue-700/10";
                    indicator.textContent = "Current Turn";
                    playerDiv.appendChild(indicator);
                  }
                } else if (turnIndicator) {
                  turnIndicator.remove();
                }
              });

            // Update the Send Random Move button state
            const moveButton = document.querySelector(
              'button[onclick="sendRandomMove()"]'
            );
            if (moveButton) {
              const currentUserId = parseInt(
                document.querySelector("[data-current-user]")?.dataset
                  .currentUser
              );
              moveButton.disabled = currentUserId !== data.current_turn_id;
            }

            // TODO: Update game board visualization
          } else if (data.status === "error") {
            console.error("Move error:", data.errors);
            alert("Invalid move: " + data.errors.join(", "));
          }
        }
      },
    }
  );
}

// Connect when the page loads
document.addEventListener("turbo:load", connectToGameChannel);
// Reconnect when Turbo renders a frame
document.addEventListener("turbo:render", connectToGameChannel);
