"""Push sheet_payload.json into the GPTfy Skill Library Google Sheet via Sheets API (ADC)."""
from __future__ import annotations

import json
from pathlib import Path

from google.auth import default
from googleapiclient.discovery import build

SHEET_ID = "1LHw46KlgmFam2cX5sMBPSIxEYNrEUqx7E22ihp-9K5E"
ROOT = Path(__file__).resolve().parents[2]
EXPORTS = ROOT / "Reports" / "exports"
PAYLOAD_PATH = EXPORTS / "sheet_payload.json"


def str_cells(rows: list) -> list[list[str]]:
    out: list[list[str]] = []
    for r in rows:
        out.append([("" if c is None else str(c)[:49000]) for c in r])
    return out


def main() -> None:
    payload = json.loads(PAYLOAD_PATH.read_text(encoding="utf-8"))
    creds, _ = default(scopes=["https://www.googleapis.com/auth/spreadsheets"])
    svc = build("sheets", "v4", credentials=creds, cache_discovery=False)

    meta = svc.spreadsheets().get(spreadsheetId=SHEET_ID).execute()
    titles = {s["properties"]["title"] for s in meta.get("sheets", [])}
    print("tabs:", sorted(titles))

    requests = []
    if "E2E Results" not in titles:
        requests.append({"addSheet": {"properties": {"title": "E2E Results"}}})
    if "Skill Field Guide" not in titles:
        requests.append({"addSheet": {"properties": {"title": "Skill Field Guide"}}})
    if "Summary" not in titles and "Sheet1" in titles:
        sheet1_id = next(
            s["properties"]["sheetId"]
            for s in meta["sheets"]
            if s["properties"]["title"] == "Sheet1"
        )
        requests.append(
            {
                "updateSheetProperties": {
                    "properties": {"sheetId": sheet1_id, "title": "Summary"},
                    "fields": "title",
                }
            }
        )
    if requests:
        svc.spreadsheets().batchUpdate(
            spreadsheetId=SHEET_ID, body={"requests": requests}
        ).execute()
        print("updated structure")

    for tab in ["Summary", "E2E Results", "Skill Field Guide"]:
        try:
            svc.spreadsheets().values().clear(
                spreadsheetId=SHEET_ID, range=f"{tab}!A:Z"
            ).execute()
        except Exception as e:  # noqa: BLE001
            print("clear", tab, e)

    data = [
        {"range": "Summary!A1", "values": str_cells(payload["Summary"])},
        {"range": "E2E Results!A1", "values": str_cells(payload["E2E Results"])},
        {
            "range": "Skill Field Guide!A1",
            "values": str_cells(payload["Skill Field Guide"]),
        },
    ]
    res = (
        svc.spreadsheets()
        .values()
        .batchUpdate(
            spreadsheetId=SHEET_ID,
            body={"valueInputOption": "RAW", "data": data},
        )
        .execute()
    )
    print("updated cells total", res.get("totalUpdatedCells"))
    print("URL", f"https://docs.google.com/spreadsheets/d/{SHEET_ID}/edit")


if __name__ == "__main__":
    main()
