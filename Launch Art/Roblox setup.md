# Fuse Anything Roblox setup

1. Publish the saved place as a private test experience. Keep its audience restricted while validating cloud features.
2. Create the passes and developer products in Creator Hub. Copy their IDs into `ReplicatedStorage.Shared.ShopCatalog` in Studio and `ShopCatalog.luau` in the source folder. Configure fixed benefits to match the descriptions. Leave unprovisioned entries at zero.
3. Create the daily mystery badge and set `ReplicatedStorage.Shared.Config.DailyBadgeId`. Choose the private server price and enable private servers in Creator Hub if desired.
4. Upload `Fuse Anything Official Thumbnail.png` as the experience thumbnail. It is 1920 × 1080.
5. In the private test experience, check a real pass prompt and developer product, rejoin to verify saves, compare rankings and World Firsts from separate servers, solve the daily recipe, and check the First Rounds funnel in Creator Hub before opening the audience.

The Studio receipt test uses simulated IDs. The saved production catalog ships with IDs set to zero, so its shop cannot start a real purchase.

## Added in the Engagement Update
6. In Creator Hub → Places → Settings, set **Max Players to 8** (there are 8 Creature Lab plots).
7. Create the new **2× Lab Income** game pass (Key `LabIncome`) and paste its ID into ShopCatalog. Coin packs are now 1,000 and 5,000 coins — price them in Robux accordingly.
8. Test stealing with a friend in the private test server: steal, get caught, lock, and steal while the owner is in a round (should be blocked).
