# Gigboard Mod for Minetest
Gigboard enables players to post and apply for jobs or offer and seek services, fostering a vibrant community marketplace within Minetest.

## Key Features
- **Job and Service Listings:** Players can post and manage job offers or services, with details including Title, Description, Fee, and Type (Job/Service).
- **Player Profiles with Reviews:** Profiles show a player's history in jobs/services and an average star rating (1-5 stars) based on reviews from other players. Reviews can include a star rating and a text comment.
- **View and Interact with Profiles:** Access profiles through job listings, applicant screens, or a dedicated "Profiles" section via the `/gigboard` command.
- **Review Management:** Players can add, edit, or delete their reviews on others' profiles.
- **Manage Applicants:** Review, approve, or reject applicants for jobs.
- **Completion and Payment:** Automatic fund transfer upon mutual job completion confirmation.
- **Admin Moderation:** Admins with `gigboard_admin` privilege can manage listings and intervene in disputes.
- **Listing Limits:** Configurable limits for posting jobs and services, with defaults set at 5 each.
- **Notifications:** Alerts for significant events like job completion and applicant approval.
- **Sorting Mechanism:** Sort listings by Title, Author, and Fee.

## Economy Integration
- **Emerald Bank Dependency:** Uses Emerald Bank for initial transaction handling.
- **Wrapper Functions:** `transfer_funds` and `get_balance` for future mod compatibility.

## User Interface
- **Formspec Access:** The UI is accessible with the `/gigboard` command.
- **Profiles Access:** View profiles directly from job listings, applicant screens, or a dedicated section.
- **Intuitive Design:** Easy to navigate for all players.

## Reviews and Ratings
- **Star Ratings:** Players can rate each other from 1 to 5 stars.
- **Comment System:** Accompany star ratings with comments.
- **Editable Reviews:** Users can edit or delete their reviews.

## Conflict Resolution and Security
- **Negotiable Fees:** Job fees are negotiable, with changes subject to approval.
- **Admin Intervention:** Admins can resolve conflicts and ensure marketplace integrity.

## Storage and Data Management
- **Mod Storage:** Uses Minetest's mod storage system for data persistence.
- **Initialization:** Mod storage is initialized in the `init.lua` file.

## Configuration and Customization
- **Settings:** Customizable settings for job and service posting limits.
- **Admin Privileges:** Special privileges for server admins.

# Technical's
Behind the scenes it uses emeraldbank.transfer_emeralds(player1_name, player2_name, num_of_emeralds) to transfer emeralds and emeraldbank.get_emeralds(player_name) to check if have enough emeralds.