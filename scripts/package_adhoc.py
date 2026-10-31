#!/usr/bin/env python3
"""项目打包入口，仅使用 Python 标准库、Xcode 和 curl。"""

import argparse
import base64
import datetime
import hashlib
import hmac
import json
import os
from pathlib import Path
import plistlib
import queue
import re
import shlex
import shutil
import signal
import subprocess
import sys
import threading
import time
import urllib.error
import urllib.parse
import urllib.request


ROOT = Path(__file__).resolve().parent.parent
PGY = "https://www.pgyer.com/apiv2/app/"
FEISHU_WEBHOOK = "https://open.feishu.cn/open-apis/bot/v2/hook/df5db5ab-50d4-4e9f-a430-fd3781c34ff4"


def log(message):
    print(message, flush=True)


def load_env(path):
    """读取 dotenv 的字面量，不执行 shell；进程环境变量优先。"""
    values = {}
    if path.is_file():
        for number, line in enumerate(path.read_text().splitlines(), 1):
            line = line.strip()
            if not line or line.startswith("#"):
                continue
            if line.startswith("export "):
                line = line[7:]
            key, separator, value = line.partition("=")
            if not separator:
                raise RuntimeError(f"配置文件第 {number} 行缺少等号")
            parts = shlex.split(value, comments=True)
            values[key.strip()] = " ".join(parts)
    values.update(os.environ)
    return values


def request_json(url, fields, as_json=False, get=False):
    if get:
        url += "?" + urllib.parse.urlencode(fields)
        request = urllib.request.Request(url)
    else:
        body = (json.dumps(fields).encode() if as_json
                else urllib.parse.urlencode(fields).encode())
        content_type = "application/json" if as_json else "application/x-www-form-urlencoded"
        request = urllib.request.Request(url, body, {"Content-Type": content_type})
    try:
        with urllib.request.urlopen(request, timeout=60) as response:
            return json.load(response)
    except urllib.error.HTTPError as error:
        raise RuntimeError(f"远程接口 HTTP {error.code}") from None
    except urllib.error.URLError:
        raise RuntimeError("远程接口连接失败，请检查网络") from None


def distribution_status(directory):
    """只输出阶段摘要，避免把 Apple 账号和签名凭证写进终端。"""
    if directory is None:
        return "等待 Xcode 输出"
    markers = {
        "IDEDistributionSigningAssetsStep": "检查分发证书和描述文件（可能访问 Apple 服务）",
        "Created provisioning profile": "Ad Hoc 描述文件已创建",
        "IDEDistributionPackagingStep": "重签名并打包 IPA",
        "invoking codesign": "正在重签名 App / 内嵌框架；若有钥匙串授权弹窗，请处理",
    }
    latest = (0, "等待 Xcode 导出")
    for name in ("IDEDistribution.standard.log", "IDEDistributionProvisioning.log",
                 "IDEDistributionPipeline.log"):
        try:
            path = directory / name
            modified = path.stat().st_mtime
            with path.open("rb") as handle:
                handle.seek(max(0, path.stat().st_size - 32768))
                tail = handle.read().decode("utf-8", errors="replace")
            matches = [(tail.rfind(marker), status) for marker, status in markers.items()
                       if marker in tail]
            if matches and modified >= latest[0]:
                latest = (modified, max(matches)[1])
        except OSError:
            continue
    return latest[1]


def stop_process(process):
    # 等待子进程退出后才能清理工作目录，避免导出进程继续读写已删除的文件。
    try:
        os.killpg(process.pid, signal.SIGTERM)
    except ProcessLookupError:
        pass
    try:
        process.wait(timeout=10)
    except subprocess.TimeoutExpired:
        try:
            os.killpg(process.pid, signal.SIGKILL)
        except ProcessLookupError:
            pass
        process.wait()


def run_build(arguments, logfile, label="Release 构建", timeout=1800):
    with logfile.open("w", buffering=1) as output:
        process = subprocess.Popen(arguments, cwd=ROOT, stdout=subprocess.PIPE,
                                   stderr=subprocess.STDOUT, text=True,
                                   start_new_session=True)
        events = queue.Queue()

        def read_output():
            try:
                for line in process.stdout:
                    events.put(line)
            finally:
                events.put(None)

        threading.Thread(target=read_output, daemon=True).start()
        started = last_progress = last_output = time.monotonic()
        distribution_dir = None
        try:
            while True:
                now = time.monotonic()
                if now - started > timeout:
                    raise RuntimeError(
                        f"{label}超过 {timeout} 秒，已停止。请检查 Apple 服务连接、"
                        f"Xcode 账号或钥匙串授权。日志：{logfile}；分发日志：{distribution_dir}")
                if now - last_progress >= 15:
                    status = distribution_status(distribution_dir)
                    log(f"[{label}] 已用时 {int(now - started)} 秒，"
                        f"距上次终端输出 {int(now - last_output)} 秒；{status}；日志：{logfile}")
                    last_progress = now
                try:
                    line = events.get(timeout=1)
                except queue.Empty:
                    continue
                if line is None:
                    break
                last_output = time.monotonic()
                output.write(line)
                print(line, end="", flush=True)
                match = re.search(r'Created bundle at path "([^"]+\.xcdistributionlogs)"', line)
                if match:
                    distribution_dir = Path(match.group(1))
                    log(f"[{label}] Xcode 分发日志：{distribution_dir}")
            if process.wait(timeout=10):
                raise RuntimeError(f"{label}失败，日志：{logfile}；分发日志：{distribution_dir}")
        except BaseException:
            stop_process(process)
            raise
        finally:
            process.stdout.close()


def build_ipa(args, output):
    archive = output / "bluedXHook.xcarchive"
    products = output / "DerivedData" / "Build" / "Products" / "Release-iphoneos"
    log("开始 Release build（MonkeyDev 不支持直接 archive）…")
    run_build([
        "xcodebuild", "-project", str(ROOT / "bluedXHook.xcodeproj"),
        "-scheme", "bluedXHook", "-configuration", "Release",
        "-destination", "generic/platform=iOS",
        "-derivedDataPath", str(output / "DerivedData"),
        "-allowProvisioningUpdates", f"DEVELOPMENT_TEAM={args.team}",
        "build",
    ], output / "build.log")
    # 使用正常构建得到的最终 App 创建应用归档，再交给 Xcode 重新分发签名。
    # 不调用 createIPA.command：它仅压缩现有签名，无法保证导出的是 Ad Hoc。
    app = products / "bluedXHook.app"
    if not (app / "Info.plist").is_file():
        raise RuntimeError(f"未找到构建完成的 App：{app}")
    with (app / "Info.plist").open("rb") as handle:
        app_info = plistlib.load(handle)
    log("[组装归档] 正在复制最终 App 和符号文件…")
    applications = archive / "Products" / "Applications"
    applications.mkdir(parents=True)
    subprocess.run(["/usr/bin/ditto", str(app), str(applications / app.name)], check=True)
    archive_info = {
        "ArchiveVersion": 2,
        "CreationDate": datetime.datetime.now(datetime.timezone.utc).replace(tzinfo=None),
        "Name": "bluedXHook",
        "SchemeName": "bluedXHook",
        "ApplicationProperties": {
            "ApplicationPath": f"Applications/{app.name}",
            "CFBundleIdentifier": app_info["CFBundleIdentifier"],
            "CFBundleShortVersionString": app_info.get("CFBundleShortVersionString", "1.0"),
            "CFBundleVersion": app_info.get("CFBundleVersion", "1"),
            "Team": args.team,
        },
    }
    with (archive / "Info.plist").open("wb") as handle:
        plistlib.dump(archive_info, handle)
    for dsym in products.glob("*.dSYM"):
        destination = archive / "dSYMs" / dsym.name
        destination.parent.mkdir(exist_ok=True)
        subprocess.run(["/usr/bin/ditto", str(dsym), str(destination)], check=True)
    # Xcode 16+ 的 release-testing 即原来的 ad-hoc 导出方式。
    options = {
        "method": "release-testing", "teamID": args.team,
        "signingStyle": "automatic", "stripSwiftSymbols": True,
        "manageAppVersionAndBuildNumber": False,
    }
    export_options = output / "ExportOptions.plist"
    with export_options.open("wb") as handle:
        plistlib.dump(options, handle)
    log(f"导出 Ad Hoc IPA（自动签名可能访问 Apple 服务，最长等待 {args.export_timeout} 秒）…")
    export = output / "export"
    run_build([
        "xcodebuild", "-exportArchive", "-archivePath", str(archive),
        "-exportPath", str(export), "-exportOptionsPlist", str(export_options),
        "-allowProvisioningUpdates",
    ], output / "export.log", label="Ad Hoc 导出", timeout=args.export_timeout)
    files = list(export.glob("*.ipa"))
    if len(files) != 1:
        raise RuntimeError(f"导出目录应有一个 IPA，请查看：{export}")
    return files[0]


def upload_ipa(ipa, api_key, description, output):
    log("获取蒲公英上传凭证…")
    token = request_json(PGY + "getCOSToken", {
        "_api_key": api_key, "buildType": "ios",
        "buildUpdateDescription": description,
    })
    if token.get("code") != 0:
        raise RuntimeError(f"蒲公英获取凭证失败：{token.get('message')}")
    data = token["data"]
    if not data["endpoint"].startswith("https://"):
        raise RuntimeError("蒲公英返回的上传地址不是 HTTPS")
    command = ["curl", "--progress-bar", "--show-error", "--connect-timeout", "30",
               "--max-time", "1800", "--output", os.devnull,
               "--write-out", "%{http_code}"]
    for key in ("key", "signature", "x-cos-security-token"):
        command += ["--form-string", f"{key}={data['params'][key]}"]
    # curl 的 multipart 文件路径需要独立转义，支持空格、逗号和引号。
    escaped = str(ipa).replace("\\", "\\\\").replace('"', '\\"')
    command += ["--form", f'file=@"{escaped}"', data["endpoint"]]
    log(f"上传 IPA：{ipa}")
    # 仅捕获 HTTP 状态码，上传进度直接显示在终端。
    result = subprocess.run(command, stdout=subprocess.PIPE, text=True)
    if result.returncode or result.stdout.strip() != "204":
        raise RuntimeError(f"蒲公英文件上传失败，HTTP {result.stdout.strip() or '未知'}")
    log("文件已上传，等待蒲公英发布完成…")
    for _ in range(60):
        result = request_json(PGY + "buildInfo", {
            "_api_key": api_key, "buildKey": data["key"],
        }, get=True)
        if result.get("code") == 0:
            (output / "pgyer-result.json").write_text(
                json.dumps(result, ensure_ascii=False, indent=2))
            info = result["data"]
            shortcut = info.get("buildShortcutUrl")
            if not shortcut:
                raise RuntimeError("蒲公英已发布，但未返回下载短链接")
            url = shortcut if shortcut.startswith("https://") else "https://www.pgyer.com/" + shortcut
            return info, url
        if result.get("code") != 1247:
            raise RuntimeError(f"蒲公英发布失败：{result.get('message')}")
        log("[蒲公英] 服务器仍在发布，5 秒后再次查询…")
        time.sleep(5)
    raise RuntimeError("蒲公英发布等待超时（5 分钟），请前往后台查看，勿直接重复上传")


def notify(webhook, secret, title, content, download_url=None):
    message = {"msg_type": "interactive", "card": {
        "header": {"title": {"tag": "plain_text", "content": title}},
        "elements": [{"tag": "div", "text": {"tag": "plain_text", "content": content}}],
    }}
    if download_url:
        message["card"]["elements"].append({
            "tag": "action",
            "actions": [{
                "tag": "button",
                "text": {"tag": "plain_text", "content": "下载遇见pro"},
                "type": "primary",
                "url": download_url,
            }],
        })
    if secret:
        timestamp = str(int(time.time()))
        signature = hmac.new(f"{timestamp}\n{secret}".encode(), b"", hashlib.sha256).digest()
        message.update(timestamp=timestamp, sign=base64.b64encode(signature).decode())
    result = request_json(webhook, message, as_json=True)
    if result.get("code", result.get("StatusCode")) != 0:
        raise RuntimeError(f"飞书通知失败：{result.get('msg', result.get('StatusMessage'))}")


def cleanup(output, published):
    # 只清理本次运行创建的目录，绝不删除 --ipa 指定的外部文件。
    names = ["DerivedData", "bluedXHook.xcarchive"]
    if published:
        names.append("export")
    for name in names:
        path = output / name
        if path.exists():
            try:
                shutil.rmtree(path)
                log(f"已清理：{path}")
            except OSError as error:
                log(f"清理失败，请手动删除 {path}：{error}")
    if not published and (output / "export").exists():
        log(f"本次未确认发布成功，保留导出包用于重试：{output / 'export'}")


def main():
    parser = argparse.ArgumentParser(description="Release / Ad Hoc 打包、蒲公英上传、飞书通知")
    parser.add_argument("--description", help="更新说明，默认最近三条 Git 提交")
    parser.add_argument("--config", type=Path, default=Path(
        "/Users/bear/Desktop/ziyun/buildScript/projects/projectZiyun/.env"), help="dotenv 配置文件")
    parser.add_argument("--team", default="UDPNB3LZ37", help="Apple Developer Team ID")
    parser.add_argument("--output", type=Path, default=ROOT / "build" / "adhoc", help="产物父目录")
    parser.add_argument("--ipa", type=Path, help="跳过构建，上传已有 Ad Hoc IPA（可用于上传重试）")
    parser.add_argument("--export-timeout", type=int, default=900, help="Ad Hoc 导出超时秒数，默认 900")
    args = parser.parse_args()
    if args.export_timeout <= 0:
        parser.error("--export-timeout 必须大于 0")
    values = load_env(args.config.expanduser())
    api_key = values.get("PGYER_API_KEY")
    webhook = FEISHU_WEBHOOK
    secret = os.environ.get("FEISHU_SECRET", "")
    if not api_key:
        raise RuntimeError(f"缺少 PGYER_API_KEY，请检查 {args.config}")
    for tool in (["curl"] if args.ipa else ["curl", "xcodebuild"]):
        if not shutil.which(tool):
            raise RuntimeError(f"未找到命令：{tool}")
    ipa = args.ipa.expanduser().resolve() if args.ipa else None
    if ipa and (not ipa.is_file() or ipa.suffix.lower() != ".ipa"):
        raise RuntimeError(f"IPA 文件不存在或格式不正确：{ipa}")
    stamp = datetime.datetime.now().strftime("%Y%m%d-%H%M%S-%f")
    output = args.output.expanduser().resolve() / stamp
    output.mkdir(parents=True, exist_ok=False)
    description = args.description
    if description is None:
        commits = subprocess.run(["git", "log", "-3", "--pretty=format:%s"],
                                 cwd=ROOT, capture_output=True, text=True)
        description = commits.stdout.strip() or "Ad Hoc 内测包更新"
    stage = "打包"
    uploaded_url = ""
    try:
        ipa = ipa or build_ipa(args, output)
        log(f"IPA 已就绪：{ipa}")
        stage = "上传蒲公英"
        info, uploaded_url = upload_ipa(ipa, api_key, description, output)
        log(f"蒲公英发布成功：{uploaded_url}")
        stage = "飞书通知"
        content = (f"应用：遇见pro\n"
                   f"版本：{info.get('buildVersion', '')} ({info.get('buildVersionNo', '')})\n"
                   f"签名：Ad Hoc\n大小：{ipa.stat().st_size / 1024 / 1024:.1f} MB\n"
                   f"更新时间：{datetime.datetime.now():%Y-%m-%d %H:%M:%S}\n"
                   f"更新内容：\n{description[:2000]}\n下载地址：{uploaded_url}")
        log("[飞书] 正在发送发布成功通知…")
        notify(webhook, secret, "遇见pro iOS 内测包发布成功", content,
               download_url=uploaded_url)
        log(f"飞书通知成功；日志与发布记录：{output}")
    except Exception as error:
        if stage != "飞书通知":
            try:
                log(f"[飞书] 正在发送{stage}失败通知…")
                notify(webhook, secret, f"遇见pro{stage}失败", f"{error}\n本地产物与日志：{output}")
            except Exception as notification_error:
                log(f"失败通知未送达：{notification_error}")
        else:
            log(f"IPA 已发布，无需重复上传。下载地址：{uploaded_url}")
        raise
    finally:
        cleanup(output, published=bool(uploaded_url))


if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        log("已取消。")
        sys.exit(130)
    except Exception as error:
        print(f"错误：{error}", file=sys.stderr)
        sys.exit(1)
