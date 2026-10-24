.pragma library

const unrankedOrder = 500;
const scratchpadOrder = 1000;

const scratchpadAt = (scratchpads, workspace) => scratchpads.find(scratchpad => scratchpad.workspace === workspace) ?? null;

const orderOf = (scratchpads, workspace) => {
    const index = scratchpads.findIndex(scratchpad => scratchpad.workspace === workspace);
    if (index >= 0)
        return scratchpadOrder + index;
    return Number(workspace) || unrankedOrder;
};

const bays = (workspaces, scratchpads) => [...new Set(workspaces)].sort((first, second) => orderOf(scratchpads, first) - orderOf(scratchpads, second));

const unreadIn = title => Number(title.match(/\((\d+)\)\s*$/)?.[1] ?? 0);

const owns = (title, player) => player.trackTitle !== "" && title.includes(player.trackTitle);

const playerFor = (title, appId, titles, players) => {
    const app = appId.toLowerCase();
    return players.find(player => owns(title, player)) ?? players.find(player => player.desktopEntry !== "" && app.startsWith(player.desktopEntry.toLowerCase()) && !titles.some(other => owns(other, player))) ?? null;
};

const mediaOf = player => {
    if (!player)
        return null;
    return {
        track: [player.trackTitle, player.trackArtist].filter(part => part).join(" · "),
        playing: player.isPlaying,
        canPrevious: player.canGoPrevious,
        canToggle: player.canTogglePlaying,
        canNext: player.canGoNext
    };
};

const falloff = (distance, radius) => Math.abs(distance) < radius ? (1 + Math.cos(Math.PI * distance / radius)) / 2 : 0;

const arrange = (groups, slot, divider, center, focus, gain, radius) => {
    let length = 0;
    const starts = groups.map((group, index) => {
        if (index > 0 && group !== groups[index - 1])
            length += divider;
        length += slot;
        return length - slot;
    });
    const origin = center - length / 2;
    const extras = starts.map(start => gain * falloff(focus - origin - start - slot / 2, radius));
    const shift = starts.reduce((sum, start, index) => sum + extras[index] * Math.min(1, Math.max(0, (focus - origin - start) / slot)), 0);
    let grown = 0;
    return starts.map((start, index) => {
        const item = {
            bay: groups[index],
            x: origin - shift + start + grown,
            size: slot + extras[index]
        };
        grown += extras[index];
        return item;
    });
};

const at = (items, x) => items.findIndex(item => x >= item.x && x < item.x + item.size);

const span = (items, bay) => {
    const members = items.filter(item => item.bay === bay);
    if (members.length === 0)
        return null;
    const last = members[members.length - 1];
    return {
        x: members[0].x,
        width: last.x + last.size - members[0].x
    };
};
