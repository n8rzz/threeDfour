import consumer from "channels/consumer";

const MESSAGE_TYPE = {
  MOVE: "move",
};
const MESSAGE_STATUS = {
  ERROR: "error",
  SUCCESS: "success",
};
const GAME_SELECTORS = {
  CURRENT_USER: "[data-current-user]",
  GAME_CONTAINER: "[data-game-id]",
  MOVE_BUTTON: '[data-action="send-random-move"]',
  PLAYER_ELEMENTS: "[data-player-id]",
  TURN_INDICATOR: "[data-turn-indicator]",
};

function _updateTurnIndicator(playerId, isCurrentTurn) {
  const playerDiv = document.querySelector(`[data-player-id="${playerId}"]`);

  if (!playerDiv) {
    return;
  }

  const turnIndicator = playerDiv.querySelector(GAME_SELECTORS.TURN_INDICATOR);

  if (isCurrentTurn && !turnIndicator) {
    const indicator = document.createElement("span");

    indicator.className =
      "inline-flex items-center rounded-md bg-blue-50 px-2 py-1 text-xs font-medium text-blue-700 ring-1 ring-inset ring-blue-700/10";
    indicator.textContent = "Current Turn";
    indicator.dataset.turnIndicator = "";

    playerDiv.appendChild(indicator);

    return;
  }

  if (!isCurrentTurn && turnIndicator) {
    turnIndicator.remove();
  }
}

function _updateMoveButton(currentTurnId) {
  const moveButton = document.querySelector(GAME_SELECTORS.MOVE_BUTTON);

  if (!moveButton) {
    return;
  }

  const currentUserId = parseInt(
    document.querySelector(GAME_SELECTORS.CURRENT_USER)?.dataset.currentUser
  );

  if (!currentUserId) {
    return;
  }

  moveButton.disabled = currentUserId !== currentTurnId;
}

function _handleSuccessfulMove(data) {
  document
    .querySelectorAll(GAME_SELECTORS.PLAYER_ELEMENTS)
    .forEach((playerDiv) => {
      const playerId = parseInt(playerDiv.dataset.playerId);

      _updateTurnIndicator(playerId, playerId === data.current_turn_id);
    });

  _updateMoveButton(data.current_turn_id);
}

function _onGameChannelReceived(data) {
  if (data.type !== MESSAGE_TYPE.MOVE) {
    return;
  }

  if (data.status === MESSAGE_STATUS.ERROR) {
    alert("!!! Invalid move: " + data.errors.join(", "));

    return;
  }

  if (data.status === MESSAGE_STATUS.SUCCESS) {
    _handleSuccessfulMove(data);
  }
}

function connectToGameChannel() {
  const gameContainer = document.querySelector(GAME_SELECTORS.GAME_CONTAINER);

  if (!gameContainer) {
    return;
  }

  const gameId = gameContainer.dataset.gameId;

  if (window.gameChannel?.gameId === gameId) {
    return;
  }

  if (window.gameChannel) {
    window.gameChannel.unsubscribe();
  }

  window.gameChannel = consumer.subscriptions.create(
    { channel: "GameChannel", game_id: gameId },
    {
      connected() {
        this.gameId = gameId;
      },

      disconnected() {},

      received(data) {
        console.log("--- Received data:", data);

        _onGameChannelReceived(data);
      },
    }
  );
}

document.addEventListener("click", (event) => {
  const moveButton = event.target.closest(GAME_SELECTORS.MOVE_BUTTON);

  if (!moveButton) {
    return;
  }

  if (!window.gameChannel) {
    console.warn("No game channel found");
  }

  const randomGameMove = Array.from({ length: 3 }, () =>
    Math.floor(Math.random() * 4)
  );

  const payload = {
    game_id: document.querySelector(GAME_SELECTORS.GAME_CONTAINER).dataset
      .gameId,
    move: randomGameMove,
  };

  console.log("+++ Sending move:", payload);

  window.gameChannel.send(payload);
});

// Connect when the page loads
document.addEventListener("turbo:load", connectToGameChannel);
// Reconnect when Turbo renders a frame
document.addEventListener("turbo:render", connectToGameChannel);
