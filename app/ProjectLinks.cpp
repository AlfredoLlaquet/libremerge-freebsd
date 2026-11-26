// SPDX-License-Identifier: GPL-3.0-or-later
#include "ProjectLinks.h"

#include <QDesktopServices>
#include <QString>

namespace
{

std::function<void(const QUrl &)> &openerStandIn()
{
	static std::function<void(const QUrl &)> opener;
	return opener;
}

} // namespace

namespace lm
{

// LM4BSD BEGIN — Direct project inquiries on both BSDs to the fork, which has no issue tracker.
// QUrl projectPage()
// {
// 	return QUrl(QStringLiteral("https://github.com/iagodpassos/libremerge"));
// }
//
// QUrl projectIssuesPage()
// {
// 	return QUrl(QStringLiteral("https://github.com/iagodpassos/libremerge/issues"));
// }
//
// QUrl projectTranslationsPage()
// {
// 	return QUrl(QStringLiteral("https://github.com/iagodpassos/libremerge/issues/5"));
// }
// LM4BSD REPLACEMENT
#if defined(Q_OS_FREEBSD) || defined(Q_OS_OPENBSD)
QUrl projectPage()
{
	return QUrl(QStringLiteral("https://github.com/AlfredoLlaquet/libremerge-freebsd"));
}

QUrl projectIssuesPage()
{
	return projectPage();
}

QUrl projectTranslationsPage()
{
	return projectPage();
}
#else
QUrl projectPage()
{
	return QUrl(QStringLiteral("https://github.com/iagodpassos/libremerge"));
}

QUrl projectIssuesPage()
{
	return QUrl(QStringLiteral("https://github.com/iagodpassos/libremerge/issues"));
}

QUrl projectTranslationsPage()
{
	return QUrl(QStringLiteral("https://github.com/iagodpassos/libremerge/issues/5"));
}
#endif
// LM4BSD END

void openProjectPage(const QUrl &page)
{
	if (openerStandIn())
		openerStandIn()(page);
	else
		QDesktopServices::openUrl(page);
}

void setProjectPageOpenerForTest(std::function<void(const QUrl &page)> opener)
{
	openerStandIn() = std::move(opener);
}

} // namespace lm
