enum GameLevelKind { bubbleBay, coralCargo, reefRoute, captainsCall }

extension GameLevelKindDetails on GameLevelKind {
  String get title {
    switch (this) {
      case GameLevelKind.bubbleBay:
        return 'Bubble Bay';
      case GameLevelKind.coralCargo:
        return 'Coral Cargo Rescue';
      case GameLevelKind.reefRoute:
        return 'Reef Route Rally';
      case GameLevelKind.captainsCall:
        return "Captain's Call";
    }
  }

  String get instruction {
    switch (this) {
      case GameLevelKind.bubbleBay:
        return 'Get ready to say each sound shown on screen.';
      case GameLevelKind.coralCargo:
        return 'Say the word shown to deliver the cargo.';
      case GameLevelKind.reefRoute:
        return 'Say the short phrase shown to open the route.';
      case GameLevelKind.captainsCall:
        return 'Say the captain\'s call shown on screen.';
    }
  }
}
