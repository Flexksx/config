.pragma library

function score(app, text) {
    const name = app.name.toLowerCase();
    if (name.startsWith(text))
        return 4;
    if (name.split(/\s+/).some(word => word.startsWith(text)))
        return 3;
    if (name.includes(text))
        return 2;
    return app.text.includes(text) ? 1 : 0;
}

function rank(apps, query) {
    const needle = query.toLowerCase().trim();
    if (needle.length === 0)
        return [];
    return apps.map(app => ({
                app: app,
                score: score(app, needle)
            })).filter(candidate => candidate.score > 0).sort((a, b) => b.score - a.score || b.app.uses - a.app.uses || a.app.name.localeCompare(b.app.name)).map(candidate => candidate.app);
}

function best(apps, query) {
    return rank(apps, query)[0] ?? null;
}

function keymap(apps, query, letters, top) {
    const map = {};
    for (const letter of letters)
        map[letter] = best(apps, query + letter);
    const last = query.slice(-1).toLowerCase();
    if (top && last in map)
        map[last] = top;
    return map;
}
