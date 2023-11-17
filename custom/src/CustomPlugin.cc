/****************************************************************************
 *
 * (c) 2009-2019 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 *   @brief Custom QGCCorePlugin Implementation
 *   @author Gus Grubba <gus@auterion.com>
 */

#include <QtQml>
#include <QQmlEngine>
#include <QDateTime>
#include "QGCSettings.h"
#include "MAVLinkLogManager.h"

#include "CustomPlugin.h"

#include "MultiVehicleManager.h"
#include "QGCApplication.h"
#include "SettingsManager.h"
#include "AppMessages.h"
#include "QmlComponentInfo.h"
#include "QGCPalette.h"

QGC_LOGGING_CATEGORY(CustomLog, "CustomLog")

CustomOptions::CustomOptions(CustomPlugin *, QObject *parent)
    : QGCOptions(parent)
{
}

CustomPlugin::CustomPlugin(QGCApplication *app, QGCToolbox *toolbox)
    : QGCCorePlugin(app, toolbox)
{
    _options = new CustomOptions(this, this);
    _showAdvancedUI = false;
}

CustomPlugin::~CustomPlugin()
{
}

//-----------------------------------------------------------------------------
void CustomPlugin::_addSettingsEntry(const QString &title, const char *qmlFile, const char *iconFile)
{
    Q_CHECK_PTR(qmlFile);
    // 'this' instance will take ownership on the QmlComponentInfo instance
    _customSettingsList.append(QVariant::fromValue(
        new QmlComponentInfo(title,
                             QUrl::fromUserInput(qmlFile),
                             iconFile == nullptr ? QUrl() : QUrl::fromUserInput(iconFile),
                             this)));
}

//-----------------------------------------------------------------------------
QVariantList &
CustomPlugin::settingsPages()
{
    if (_customSettingsList.isEmpty())
    {
        _addSettingsEntry(tr("General"), "qrc:/qml/GeneralSettings.qml", "qrc:/res/gear-white.svg");
        _addSettingsEntry(tr("Comm Links"), "qrc:/qml/LinkSettings.qml", "qrc:/res/waves.svg");
        _addSettingsEntry(tr("Offline Maps"), "qrc:/qml/OfflineMap.qml", "qrc:/res/waves.svg");
        _addSettingsEntry(tr("MAVLink"), "qrc:/qml/MavlinkSettings.qml", "qrc:/res/waves.svg");
        _addSettingsEntry(tr("Console"), "qrc:/qml/QGroundControl/Controls/AppMessages.qml");
#if defined(QT_DEBUG)
        //-- These are always present on Debug builds
        _addSettingsEntry(tr("Mock Link"), "qrc:/qml/MockLink.qml");
#endif
    }
    return _customSettingsList;
}

QGCOptions *CustomPlugin::options()
{
    return _options;
}

QString CustomPlugin::brandImageIndoor(void) const
{
    return QStringLiteral("/custom/img/CustomAppIcon.png");
}

QString CustomPlugin::brandImageOutdoor(void) const
{
    return QStringLiteral("/custom/img/CustomAppIcon.png");
}

// We override this so we can get access to QQmlApplicationEngine and use it to register our qml module
QQmlApplicationEngine *CustomPlugin::createQmlApplicationEngine(QObject *parent)
{
    QQmlApplicationEngine *qmlEngine = QGCCorePlugin::createQmlApplicationEngine(parent);
    qmlEngine->addImportPath("qrc:/Custom/Widgets");
    return qmlEngine;
}
