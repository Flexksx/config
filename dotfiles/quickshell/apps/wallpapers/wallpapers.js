.pragma library

const minorWords = ["a", "an", "the", "and", "but", "or", "nor", "of", "in", "on", "at", "by", "to", "for", "with", "from", "as", "per", "via"];

function titleCase(text) {
    const words = text.replace(/\.[^.]+$/, "").split(/[_\-\s]+/).filter(word => word.length > 0);
    return words.map((word, index) => {
        const lower = word.toLowerCase();
        if (index > 0 && minorWords.includes(lower))
            return lower;
        return word.charAt(0).toUpperCase() + word.slice(1);
    }).join(" ");
}

function decorate(wallpaper) {
    const title = titleCase(wallpaper.name);
    return Object.assign({}, wallpaper, {
        title: title,
        search: [title, wallpaper.name, wallpaper.mode].concat(wallpaper.tags).join(" ").toLowerCase()
    });
}

function filter(items, query, mode, tags, preferred) {
    const words = query.toLowerCase().split(/\s+/).filter(word => word.length > 0);
    const rank = item => item.mode === preferred ? 0 : 1;
    return items.filter(item => (mode === "all" || item.mode === mode) && tags.every(tag => item.tags.includes(tag)) && words.every(word => item.search.includes(word))).sort((a, b) => b.uses - a.uses || rank(a) - rank(b) || a.title.localeCompare(b.title));
}

function tagOptions(items) {
    const counts = {};
    for (const item of items)
        for (const tag of item.tags)
            counts[tag] = (counts[tag] || 0) + 1;
    return Object.keys(counts).sort((a, b) => counts[b] - counts[a] || a.localeCompare(b)).map(tag => ({
                value: tag,
                label: titleCase(tag) + "  " + counts[tag]
            }));
}
