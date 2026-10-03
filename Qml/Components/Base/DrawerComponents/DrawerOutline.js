.pragma library

function toPoint(options, alongEdge, acrossEdge) {
    const paddedAlongEdge = alongEdge + options.startPadding;
    const paddedAcrossEdge = acrossEdge + options.freeSidePadding;
    // frame origin: body starts at 0 along the edge, 0 is the free edge, snappedDepth is the attached edge
    switch (options.edgeName) {
    case "bottom":
        return paddedAlongEdge + " " + paddedAcrossEdge;
    case "top":
        return paddedAlongEdge + " " + (options.acrossEdgeExtent - paddedAcrossEdge);
    case "right":
        return paddedAcrossEdge + " " + paddedAlongEdge;
    default:
        return (options.acrossEdgeExtent - paddedAcrossEdge) + " " + paddedAlongEdge;
    }
}

function arc(options, radius, sweep, alongEdge, acrossEdge) {
    return "A " + radius + " " + radius + " 0 0 " + sweep + " " + toPoint(options, alongEdge, acrossEdge);
}

function buildOutline(options) {
    const borderOverlap = options.borderOverlap;
    const depth = options.snappedDepth;
    const length = options.snappedLength;
    const filletRadius = options.activeFilletRadius;
    const cornerRadius = options.activeCornerRadius;

    // arc sweeps flip on reflected edges
    const counterClockwiseSweep = options.isReflectedEdge ? 1 : 0;
    const clockwiseSweep = options.isReflectedEdge ? 0 : 1;

    let pathData = "";

    // flush sides turn the fillet 90 degrees so it blends into the side border
    if (options.isFlushToStart)
        pathData += "M " + toPoint(options, -borderOverlap, depth + borderOverlap) + " L " + toPoint(options, -borderOverlap, -filletRadius) + " L " + toPoint(options, 0, -filletRadius) + " " + arc(options, filletRadius, counterClockwiseSweep, filletRadius, 0);
    else
        pathData += "M " + toPoint(options, -filletRadius, depth + borderOverlap) + " L " + toPoint(options, -filletRadius, depth) + " " + arc(options, filletRadius, counterClockwiseSweep, 0, depth - filletRadius) + " L " + toPoint(options, 0, cornerRadius) + " " + arc(options, cornerRadius, clockwiseSweep, cornerRadius, 0);

    // one closed path: separate shapes sharing an edge left a hairline seam
    if (options.isFlushToEnd)
        pathData += " L " + toPoint(options, length - filletRadius, 0) + " " + arc(options, filletRadius, counterClockwiseSweep, length, -filletRadius) + " L " + toPoint(options, length + borderOverlap, -filletRadius) + " L " + toPoint(options, length + borderOverlap, depth + borderOverlap);
    else
        pathData += " L " + toPoint(options, length - cornerRadius, 0) + " " + arc(options, cornerRadius, clockwiseSweep, length, cornerRadius) + " L " + toPoint(options, length, depth - filletRadius) + " " + arc(options, filletRadius, counterClockwiseSweep, length + filletRadius, depth) + " L " + toPoint(options, length + filletRadius, depth + borderOverlap);

    return pathData + " Z";
}