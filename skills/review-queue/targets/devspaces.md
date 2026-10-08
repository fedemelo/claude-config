# A review workspace per PR

For the `devspaces` environment. Reached from the [review-queue](../SKILL.md) skill, which decides that this is the right procedure. Everything that skill says still holds; this file only says what a space is here and how to open one.

Each PR gets its own devspaces workspace, and every one of those workspaces is filed in the group named exactly `Local Review`. Both halves are the point of this path: a workspace per PR keeps the checkouts from colliding, and the group is what keeps eight reviews out of the groups you work in. File each workspace in that group as you create it, rather than somewhere else to be moved later.

Take the commands from the pod's own `devspaces` CLI rather than from memory, since its flags are free to change: read its help, then use whatever it offers for listing groups, creating a group, creating a workspace, filing that workspace in a group, listing the workspaces in one, and giving a new workspace a starting prompt. Seed each one with `/local-review <url>`, so the review is running when you arrive.

Find the group before creating anything. List the groups and look for one named exactly `Local Review`. If it exists, file every workspace in it, even when it is empty; create the group only when none has that name. A second `Local Review` group splits the queue in two, and the reviews filed in the new one are the ones you will not find. If more than one group already has that name, stop and report them all, rather than choosing one.

Then read the workspaces already in that group. One named for a PR in the list means that review is already queued, so leave it as it is: a second workspace for the same PR is the duplicate this step exists to prevent, and the one already there may hold a review you have not read.

If the CLI will not do one of those things, that is the end of this path. Stop and report it. No worktrees, no background sessions, no reviews here.

## Reading spaces back

The skip check and the cleanup step both read the workspaces in the `Local Review` group. A workspace named `review-<n>` is PR `<n>`'s space.

In the report, "how to reach it" is the workspace's name.
