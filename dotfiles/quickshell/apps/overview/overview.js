.pragma library

const sum = values => values.reduce((total, value) => total + value, 0);

const coordinateCount = 2;

const placed = client => client && client.at?.length === coordinateCount && client.size?.length === coordinateCount && !client.hidden;

const frameOf = (client, origin) => ({
    x: client.at[0] - origin.x,
    y: client.at[1] - origin.y,
    width: client.size[0],
    height: client.size[1]
});

const leftToRight = (first, second) => first.x - second.x || first.y - second.y;

const rowsOf = (frames, count) => {
    const target = sum(frames.map(frame => frame.width)) / count;
    const rows = Array.from({
        length: count
    }, () => []);
    let before = 0;
    frames.forEach((frame, index) => {
        rows[Math.min(count - 1, Math.floor((before + frame.width / 2) / target))].push(index);
        before += frame.width;
    });
    return rows.filter(row => row.length > 0);
};

const tallestIn = (frames, row) => Math.max(...row.map(index => frames[index].height));

const fitOf = (frames, rows, area, gaps) => {
    const across = Math.min(...rows.map(row => (area.width - gaps.column * (row.length - 1)) / sum(row.map(index => frames[index].width))));
    const down = (area.height - gaps.row * (rows.length - 1)) / sum(rows.map(row => tallestIn(frames, row)));
    return Math.min(across, down);
};

const arrange = (frames, area, gaps, maxScale) => {
    if (frames.length === 0)
        return [];
    const best = frames.map((frame, index) => rowsOf(frames, index + 1)).map(rows => ({
                rows: rows,
                fit: fitOf(frames, rows, area, gaps)
            })).reduce((winner, candidate) => candidate.fit > winner.fit ? candidate : winner);
    const scale = Math.min(maxScale, best.fit);
    const heights = best.rows.map(row => tallestIn(frames, row) * scale);
    const slots = [];
    let y = area.y + (area.height - sum(heights) - gaps.row * (heights.length - 1)) / 2;
    best.rows.forEach((row, rowIndex) => {
        let x = area.x + (area.width - sum(row.map(index => frames[index].width * scale)) - gaps.column * (row.length - 1)) / 2;
        for (const index of row) {
            const width = frames[index].width * scale;
            const height = frames[index].height * scale;
            slots[index] = {
                x: x,
                y: y + (heights[rowIndex] - height) / 2,
                width: width,
                height: height
            };
            x += width + gaps.column;
        }
        y += heights[rowIndex] + gaps.row;
    });
    return slots;
};

const between = (from, to, progress) => ({
    x: from.x + (to.x - from.x) * progress,
    y: from.y + (to.y - from.y) * progress,
    width: from.width + (to.width - from.width) * progress,
    height: from.height + (to.height - from.height) * progress
});

const strip = (count, area, aspect, gap) => {
    const width = Math.min(area.height * aspect, (area.width - gap * (count - 1)) / count);
    const start = area.x + (area.width - width * count - gap * (count - 1)) / 2;
    return Array.from({
        length: count
    }, (slot, index) => ({
                x: start + index * (width + gap),
                y: area.y,
                width: width,
                height: width / aspect
            }));
};
