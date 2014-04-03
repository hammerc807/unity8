/*
 * Copyright 2014 Canonical Ltd.
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 3.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import QtQuick 2.0
import QtTest 1.0
import Unity.Test 0.1 as UT
import ".."
import "../../../qml/Stages"
import Ubuntu.Components 0.1
import Unity.Application 0.1

Item {
    width: units.gu(70)
    height: units.gu(70)

    Rectangle {

    }

    PhoneStage {
        id: phoneStage
        anchors { fill: parent; rightMargin: units.gu(30) }
        shown: true
        dragAreaWidth: units.gu(2)
    }

    Binding {
        target: ApplicationManager
        property: "rightMargin"
        value: phoneStage.anchors.rightMargin
    }

    Rectangle {
        anchors { fill: parent; leftMargin: phoneStage.width }
//        color: "blue"

        Column {
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: units.gu(1) }
            spacing: units.gu(1)
            Button {
                anchors { left: parent.left; right: parent.right }
                text: "Add App"
                onClicked: {
                    testCase.addApps();
                }
            }
            Button {
                anchors { left: parent.left; right: parent.right }
                text: "Add App"
            }
        }
    }

    UT.UnityTestCase {
        id: testCase
        name: "PhoneStage"
        when: windowShown

        function addApps(count) {
            if (count == undefined) count = 1;
            for (var i = 0; i < count; i++) {
                var app = ApplicationManager.startApplication(ApplicationManager.availableApplications()[ApplicationManager.count])
                tryCompare(app, "state", ApplicationInfoInterface.Running)
                // Fixme: Right now there is a timeout in the PhoneStage that displays a white splash
                // screen rectangle when an app starts. This is because we don't yet have a way of
                // knowing when an app has finished launching. That workaround and this wait() should
                // go away at some point and the app's state only changing to Running when ready for real.
//                wait(1000)
                waitForRendering(phoneStage)
            }
        }

        function goToSpread() {
            var spreadView = findChild(phoneStage, "spreadView");

            var startX = phoneStage.width;
            var startY = phoneStage.height / 2;
            var endY = startY;
            var endX = units.gu(2);

            touchFlick(phoneStage, startX, startY, endX, endY,
                       true /* beginTouch */, true /* endTouch */, units.gu(10), 50);
        }

        function test_shortFlick() {
            addApps(2)
            var startX = phoneStage.width - units.gu(1);
            var startY = phoneStage.height / 2;
            var endX = phoneStage.width / 2;
            var endY = startY;

            var activeApp = ApplicationManager.get(0);
            var inactiveApp = ApplicationManager.get(1);

            touchFlick(phoneStage, startX, startY, endX, endY,
                       true /* beginTouch */, true /* endTouch */, units.gu(10), 50);

            tryCompare(ApplicationManager, "focusedApplicationId", inactiveApp.appId)

            touchFlick(phoneStage, startX, startY, endX, endY,
                       true /* beginTouch */, true /* endTouch */, units.gu(10), 50);

            tryCompare(ApplicationManager, "focusedApplicationId", activeApp.appId)

            tryCompare(phoneStage, "painting", false);
        }

        function test_enterSpread_data() {
            return [
                {tag: "<position1 (linear movement)", positionMarker: "positionMarker1", linear: true, offset: -1, endPhase: 0, targetPhase: 0, newFocusedIndex: 1 },
                {tag: "<position1 (non-linear movement)", positionMarker: "positionMarker1", linear: false, offset: -1, endPhase: 0, targetPhase: 0, newFocusedIndex: 0 },
                {tag: ">position1", positionMarker: "positionMarker1", linear: true, offset: +1, endPhase: 0, targetPhase: 0, newFocusedIndex: 1 },
                {tag: "<position2 (linear)", positionMarker: "positionMarker2", linear: true, offset: -1, endPhase: 0, targetPhase: 0, newFocusedIndex: 1 },
                {tag: "<position2 (non-linear)", positionMarker: "positionMarker2", linear: false, offset: -1, endPhase: 0, targetPhase: 0, newFocusedIndex: 1 },
                {tag: ">position2", positionMarker: "positionMarker2", linear: true, offset: +1, endPhase: 1, targetPhase: 0, newFocusedIndex: 1 },
                {tag: "<position3", positionMarker: "positionMarker3", linear: true, offset: -1, endPhase: 1, targetPhase: 0, newFocusedIndex: 1 },
                {tag: ">position3", positionMarker: "positionMarker3", linear: true, offset: +1, endPhase: 2, targetPhase: 2, newFocusedIndex: 2 },
            ];
        }

        function test_enterSpread(data) {
            addApps(5)

            var spreadView = findChild(phoneStage, "spreadView");

            var startX = phoneStage.width;
            var startY = phoneStage.height / 2;
            var endY = startY;
            var endX = spreadView.width - (spreadView.width * spreadView[data.positionMarker]) - data.offset - phoneStage.dragAreaWidth;

            var oldFocusedApp = ApplicationManager.get(0);
            var newFocusedApp = ApplicationManager.get(data.newFocusedIndex);

            touchFlick(phoneStage, startX, startY, endX, endY,
                       true /* beginTouch */, false /* endTouch */, units.gu(10), 50);

            tryCompare(spreadView, "phase", data.endPhase)

            if (!data.linear) {
                touchFlick(phoneStage, endX, endY, endX + units.gu(.5), endY,
                           false /* beginTouch */, false /* endTouch */, units.gu(10), 50);
                touchFlick(phoneStage, endY + units.gu(.5), endY, endX, endY,
                           false /* beginTouch */, false /* endTouch */, units.gu(10), 50);
            }

            touchRelease(phoneStage, endX, endY);

            tryCompare(spreadView, "phase", data.targetPhase)

            if (data.targetPhase == 2) {
                var app2 = findChild(spreadView, "appDelegate2");
                mouseClick(app2, units.gu(1), units.gu(1));
            }

            tryCompare(phoneStage, "painting", false);
            tryCompare(ApplicationManager, "focusedApplicationId", newFocusedApp.appId);
        }

        function test_selectAppFromSpread_data() {
            var appsToTest = 6;
            var apps = new Array();
            for (var i = 0; i < appsToTest; i++) {
                var item = new Object();
                item.tag = "App " + i;
                item.index = i;
                item.total = appsToTest;
                apps.push(item)
            }
            return apps;
        }

        function test_selectAppFromSpread(data) {
            addApps(data.total)

            var spreadView = findChild(phoneStage, "spreadView");

            goToSpread();

            tryCompare(spreadView, "phase", 2);

            var tile = findChild(spreadView, "appDelegate" + data.index);
            var appId = ApplicationManager.get(data.index).appId;

            if (tile.mapToItem(spreadView).x > spreadView.width) {
                // Item is not visible... Need to flick the spread
                var startX = phoneStage.width - units.gu(1);
                var startY = phoneStage.height / 2;
                var endY = startY;
                var endX = units.gu(2);
                touchFlick(phoneStage, startX, startY, endX, endY, true, true, units.gu(10), 50)
                tryCompare(spreadView, "flicking", false);
                tryCompare(spreadView, "moving", false);
//                waitForRendering(phoneStage);
            }

            console.log("clicking app", data.index, "(", appId, ")")
            mouseClick(spreadView, tile.mapToItem(spreadView).x + units.gu(1), spreadView.height / 2)
            tryCompare(ApplicationManager, "focusedApplicationId", appId);
            tryCompare(spreadView, "phase", 0);
        }

        function test_animateAppStartup() {
            compare(phoneStage.painting, false);
            addApps(2);
            tryCompare(phoneStage, "painting", true);
            tryCompare(phoneStage, "painting", false);
            addApps(1);
            tryCompare(phoneStage, "painting", true);
            tryCompare(phoneStage, "painting", false);
        }

        function test_select_data() {
            return [
                { tag: "0", index: 0 },
                { tag: "2", index: 2 },
                { tag: "4", index: 4 },
            ]
        }

        function test_select(data) {
            addApps(5);

            var spreadView = findChild(phoneStage, "spreadView");
            var selectedApp = ApplicationManager.get(data.index);

            goToSpread();

            phoneStage.select(selectedApp.appId);

            tryCompare(phoneStage, "painting", false);
            compare(ApplicationManager.focusedApplicationId, selectedApp.appId);
        }

        function test_fullscreenMode() {
            var fullscreenApp = null;
            var normalApp = null;

            for (var i = 0; i < 5; i++) {
                addApps(1);
                var newApp = ApplicationManager.get(0);
                tryCompare(phoneStage, "fullscreen", newApp.fullscreen);
                if (newApp.fullscreen && fullscreenApp == null) {
                    fullscreenApp = newApp;
                } else if (!newApp.fullscreen && normalApp == null){
                    normalApp = newApp;
                }
            }
            verify(fullscreenApp != null); // Can't continue the test without having a fullscreen app
            verify(normalApp != null); // Can't continue the test without having a non-fullscreen app

            // Select a normal app
            goToSpread();
            phoneStage.select(normalApp.appId);
            tryCompare(phoneStage, "fullscreen", false);

            // Select a fullscreen app
            goToSpread();
            phoneStage.select(fullscreenApp.appId);
            tryCompare(phoneStage, "fullscreen", true);

            // Select a normal app
            goToSpread();
            phoneStage.select(normalApp.appId);
            tryCompare(phoneStage, "fullscreen", false);
        }

        function cleanup() {
            while (ApplicationManager.count > 0) {
                var oldCount = ApplicationManager.count;
                ApplicationManager.stopApplication(ApplicationManager.get(0).appId)
                tryCompare(ApplicationManager, "count", oldCount - 1)
            }
        }
    }
}