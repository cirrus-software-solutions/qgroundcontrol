/****************************************************************************
 *
 * (c) 2009-2020 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

import QtQuick                  2.12
import QtQuick.Controls         2.4
import QtQuick.Dialogs          1.3
import QtQuick.Layouts          1.12

import QtLocation               5.3
import QtPositioning            5.3
import QtQuick.Window           2.2
import QtQml.Models             2.1

import QGroundControl               1.0
import QGroundControl.Airspace      1.0
import QGroundControl.Airmap        1.0
import QGroundControl.Controllers   1.0
import QGroundControl.Controls      1.0
import QGroundControl.FactSystem    1.0
import QGroundControl.FlightDisplay 1.0
import QGroundControl.FlightMap     1.0
import QGroundControl.Palette       1.0
import QGroundControl.ScreenTools   1.0
import QGroundControl.Vehicle       1.0

Item {
    id: _root

    // These should only be used by MainRootWindow
    property var planController:    _planController
    property var guidedController:  _guidedController

    PlanMasterController {
        id:                     _planController
        flyView:                true
        Component.onCompleted:  start()
    }

    property bool   _mainWindowIsMap:       mapControl.pipState.state === mapControl.pipState.fullState
    property bool   _isFullWindowItemDark:  _mainWindowIsMap ? mapControl.isSatelliteMap : true
    property var    _activeVehicle:         QGroundControl.multiVehicleManager.activeVehicle
    property var    _missionController:     _planController.missionController
    property var    _geoFenceController:    _planController.geoFenceController
    property var    _rallyPointController:  _planController.rallyPointController
    property real   _margins:               ScreenTools.defaultFontPixelWidth / 2
    property var    _guidedController:      guidedActionsController
    property var    _guidedActionList:      guidedActionList
    property var    _guidedValueSlider:       guidedValueSlider
    property real   _toolsMargin:           ScreenTools.defaultFontPixelWidth * 0.75
    property rect   _centerViewport:        Qt.rect(0, 0, width, height)
    property real   _rightPanelWidth:       ScreenTools.defaultFontPixelWidth * 30
    property var    _mapControl:            mapControl

    property real   _fullItemZorder:    0
    property real   _pipItemZorder:     QGroundControl.zOrderWidgets

    function _calcCenterViewPort() {
        var newToolInset = Qt.rect(0, 0, width, height)
        toolstrip.adjustToolInset(newToolInset)
        if (QGroundControl.corePlugin.options.instrumentWidget) {
            flightDisplayViewWidgets.adjustToolInset(newToolInset)
        }
    }

    QGCToolInsets {
        id:                     _toolInsets
        leftEdgeBottomInset:    _pipOverlay.visible ? _pipOverlay.x + _pipOverlay.width : 0
        bottomEdgeLeftInset:    _pipOverlay.visible ? parent.height - _pipOverlay.y : 0
    }

    // This contains all the other widgets 
    FlyViewWidgetLayer {
        id:                     widgetLayer
        anchors.top:            parent.top
        anchors.bottom:         parent.bottom
        anchors.left:           parent.left
        anchors.right:          guidedValueSlider.visible ? guidedValueSlider.left : parent.right
        z:                      _fullItemZorder + 1
        parentToolInsets:       _toolInsets
        mapControl:             _mapControl
        visible:                !QGroundControl.videoManager.fullScreen
    }

    FlyViewCustomLayer {
        id:                 customOverlay
        anchors.fill:       widgetLayer
        z:                  _fullItemZorder + 2
        parentToolInsets:   widgetLayer.totalToolInsets
        mapControl:         _mapControl
        visible:            !QGroundControl.videoManager.fullScreen
    }

    GuidedActionsController {
        id:                 guidedActionsController
        missionController:  _missionController
        actionList:         _guidedActionList
        guidedValueSlider:     _guidedValueSlider
    }

    /*GuidedActionConfirm {
        id:                         guidedActionConfirm
        anchors.margins:            _margins
        anchors.bottom:             parent.bottom
        anchors.horizontalCenter:   parent.horizontalCenter
        z:                          QGroundControl.zOrderTopMost
        guidedController:           _guidedController
        guidedValueSlider:             _guidedValueSlider
    }*/

    GuidedActionList {
        id:                         guidedActionList
        anchors.margins:            _margins
        anchors.bottom:             parent.bottom
        anchors.horizontalCenter:   parent.horizontalCenter
        z:                          QGroundControl.zOrderTopMost
        guidedController:           _guidedController
    }

    //-- Guided value slider (e.g. altitude)
    GuidedValueSlider {
        id:                 guidedValueSlider
        anchors.margins:    _toolsMargin
        anchors.right:      parent.right
        anchors.top:        parent.top
        anchors.bottom:     parent.bottom
        z:                  QGroundControl.zOrderTopMost
        radius:             ScreenTools.defaultFontPixelWidth / 2
        width:              ScreenTools.defaultFontPixelWidth * 10
        color:              qgcPal.window
        visible:            false
    }

    FlyViewMap {
        id:                     mapControl
        planMasterController:   _planController
        rightPanelWidth:        ScreenTools.defaultFontPixelHeight * 9
        pipMode:                !_mainWindowIsMap
        toolInsets:             customOverlay.totalToolInsets
        mapName:                "FlightDisplayView"
    }

    Rectangle {
        id:                     mapControl2
        property bool pipMode:                !_mainWindowIsMap
        color: "white"
        property Item pipState: _pipState
        QGCPipState {
        id:         _pipState
        pipOverlay: _pipOverlay
        isDark:     _isFullWindowItemDark
        }
        Rectangle {
            id: leftPanel
            width: parent.width /3 - 10
            height: parent.height-1
            x: 5
            color: "#333333"

            Rectangle {
                width: parent.width
                height: 30
                color: "#222222"

                Text {
                    anchors.centerIn: parent
                    text: "QGC Logs"
                    color: "white"
                    font.bold: true
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: {

                    }
                }
            }

            Rectangle {
                anchors {
                    left: parent.left
                    right: parent.right
                    top: parent.top
                    bottom: parent.bottom
                    margins: 30
                }
                color: "#333333"


                Component {
                    id: delegateItem
                    Rectangle {
                        color:  index % 2 == 0 ? qgcPal.window : qgcPal.windowShade
                        height: Math.round(ScreenTools.defaultFontPixelHeight * 0.5 + field.height)
                        width:  listview.width

                        QGCLabel {
                            id:         field
                            text:       display
                            width:      parent.width
                            wrapMode:   Text.Wrap
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                }


                QGCListView {
                    Component.onCompleted: {
                        loaded = true
                    }
                    anchors.top:     parent.top
                    anchors.left:    parent.left
                    anchors.right:   parent.right
                    anchors.bottom:  followTail.top
                    anchors.fill: parent
                    anchors.bottomMargin: ScreenTools.defaultFontPixelWidth
                    clip:            true
                    id:              listview
                    model:           debugMessageModel
                    delegate:        delegateItem
                }
            }
        }

        Rectangle {
            id: centerPanel
            width: parent.width /3 -10
            height: parent.height-1
            x: parent.width /3 + 5
            color: "#333333"


            Rectangle {
                width: parent.width
                height: 30
                color: "#222222"

                Text {
                    anchors.centerIn: parent
                    text: "Flight Info"
                    color: "white"
                    font.bold: true
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: {

                    }
                }
            }

            Rectangle {
                anchors {
                    left: parent.left
                    right: parent.right
                    top: parent.top
                    bottom: parent.bottom
                    margins: 30
                }
                color: "#333333"

                Item {
                    anchors.fill: parent
                TelemetryValuesBar {
                    id:                 telemetryPanel
                    x:                  recalcXPosition()
                    anchors.margins:    _toolsMargin
                    // visible: false

                    // States for custom layout support
                    states: [
                        State {
                            name: "bottom"
                            when: telemetryPanel.bottomMode

                            AnchorChanges {
                                target: telemetryPanel
                                anchors.left: parent.left
                                anchors.right: parent.right
                            }

                            PropertyChanges {
                                target: telemetryPanel
                                x: recalcXPosition()
                            }
                        },

                        State {
                            name: "right-video"
                            when: !telemetryPanel.bottomMode && photoVideoControl.visible

                            AnchorChanges {
                                target: telemetryPanel
                                anchors.top: photoVideoControl.bottom
                                anchors.bottom: undefined
                                anchors.right: parent.right
                                anchors.verticalCenter: undefined
                            }
                        },

                        State {
                            name: "right-novideo"
                            when: !telemetryPanel.bottomMode && !photoVideoControl.visible

                            AnchorChanges {
                                target: telemetryPanel
                                anchors.top: undefined
                                anchors.bottom: undefined
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }
                    ]

                    function recalcXPosition() {
                        // First try centered
                        var halfRootWidth   = _root.width / 2
                        var halfPanelWidth  = telemetryPanel.width / 2
                        var leftX           = (halfRootWidth - halfPanelWidth) - _toolsMargin
                        var rightX          = (halfRootWidth + halfPanelWidth) + _toolsMargin
                        if (leftX >= parentToolInsets.leftEdgeBottomInset || rightX <= parentToolInsets.rightEdgeBottomInset ) {
                            // It will fit in the horizontalCenter
                            return halfRootWidth - halfPanelWidth
                        } else {
                            // Anchor to left edge
                            return parentToolInsets.leftEdgeBottomInset + _toolsMargin
                        }
                    }
                }
                }
            }
        }

        Rectangle {
            id: rightPanel
            width: parent.width /3 -10
            height: parent.height -1
            x: parent.width *2 /3 + 5
            color: "#333333"

            Rectangle {
                width: parent.width
                height: 30
                color: "#222222"

                Text {
                    anchors.centerIn: parent
                    text: "Mavlink Messages"
                    color: "white"
                    font.bold: true
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: {

                    }
                }
            }

            Rectangle {
                anchors {
                    left: parent.left
                    right: parent.right
                    top: parent.top
                    bottom: parent.bottom
                    margins: 30
                }
                color: "#333333"

                Item {
                    anchors.fill: parent
                                    Column {
                    id:         mavStatusColumn
                    width:      gcsColumn.width
                    spacing:    _columnSpacing
                    anchors.centerIn: parent
                    Row {
                        spacing:    ScreenTools.defaultFontPixelWidth
                        anchors.horizontalCenter: parent.horizontalCenter
                        QGCLabel {
                            width:              _labelWidth
                            text:               qsTr("Total messages sent (computed):")
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        QGCLabel {
                            width:              _valueWidth
                            text:               globals.activeVehicle ? globals.activeVehicle.mavlinkSentCount : qsTr("Not Connected")
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                    //-----------------------------------------------------------------
                    Row {
                        spacing:    ScreenTools.defaultFontPixelWidth
                        anchors.horizontalCenter: parent.horizontalCenter
                        QGCLabel {
                            width:              _labelWidth
                            text:               qsTr("Total messages received:")
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        QGCLabel {
                            width:              _valueWidth
                            text:               globals.activeVehicle ? globals.activeVehicle.mavlinkReceivedCount : qsTr("Not Connected")
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                    //-----------------------------------------------------------------
                    Row {
                        spacing:    ScreenTools.defaultFontPixelWidth
                        anchors.horizontalCenter: parent.horizontalCenter
                        QGCLabel {
                            width:              _labelWidth
                            text:               qsTr("Total message loss:")
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        QGCLabel {
                            width:              _valueWidth
                            text:               globals.activeVehicle ? globals.activeVehicle.mavlinkLossCount : qsTr("Not Connected")
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                    //-----------------------------------------------------------------
                    Row {
                        spacing:    ScreenTools.defaultFontPixelWidth
                        anchors.horizontalCenter: parent.horizontalCenter
                        QGCLabel {
                            width:              _labelWidth
                            text:               qsTr("Loss rate:")
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        QGCLabel {
                            width:              _valueWidth
                            text:               globals.activeVehicle ? globals.activeVehicle.mavlinkLossPercent.toFixed(0) + '%' : qsTr("Not Connected")
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                    }
                }
            }
        }


    }

    FlyViewVideo {
        id: videoControl
    }

    Rectangle{
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        width: parent.width * 0.4
        height: parent.height * 0.06

        Button {
            text: "Swap Picture Mode"
            onClicked: _pipOverlay._swapPip()
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width * 0.48
            height: parent.height *0.9
            anchors.margins:    _toolsMargin
            palette.buttonText: "white"
            background: Rectangle {
                    color: parent.down ? "#fff291" :
                            (parent.hovered ? "#585d83" : "#222222")
                    radius: 3
            }
        }

        Button {
            text: "Switch Dock Mode"
            onClicked: _pipOverlay._swapDock()
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width * 0.48
            height: parent.height * 0.9
            anchors.margins:    _toolsMargin
            palette.buttonText: "white"
            background: Rectangle {
                    color: parent.down ? "#fff291" :
                            (parent.hovered ? "#585d83" : "#222222")
                    radius: 3
        }
        }
    }



    // Picture in picture mode
    QGCPipOverlay {
        id:                     _pipOverlay
        anchors.left:           parent.left
        anchors.bottom:         parent.bottom
        anchors.margins:        _toolsMargin
        item1IsFullSettingsKey: "MainFlyWindowIsMap"
        item1:                  mapControl
        item2:                  QGroundControl.videoManager.hasVideo ? videoControl : null
        item3:                  mapControl2
        fullZOrder:             _fullItemZorder
        pipZOrder:              _pipItemZorder
        // show:                   !QGroundControl.videoManager.fullScreen && (videoControl.pipState.state === videoControl.pipState.pipState || mapControl.pipState.state === mapControl.pipState.pipState)
        show:                   true
                               
    }
}
