import QtQuick

NumberAnimation {
    duration: Theme.durationDefault
    easing.type: Easing.BezierSpline
    easing.bezierCurve: Theme.animation.expressive.spatial.fastParams.concat([1, 1])
}
