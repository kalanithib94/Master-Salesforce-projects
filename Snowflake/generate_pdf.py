"""


Snowflake - Salesforce Integration Guide  -  PDF Generator


Beautiful redesign: system fonts, gradient cover, card-style layout.


"""


from reportlab.lib.pagesizes import A4


from reportlab.lib import colors


from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle


from reportlab.lib.units import mm


from reportlab.platypus import (


    SimpleDocTemplate, Paragraph, Spacer, PageBreak,


    KeepTogether, Table, TableStyle, Image


)


from reportlab.lib.enums import TA_LEFT, TA_CENTER, TA_RIGHT, TA_JUSTIFY


from reportlab.platypus.flowables import Flowable


from reportlab.pdfbase import pdfmetrics


from reportlab.pdfbase.ttfonts import TTFont


import os





#  -  - " - " -  Font Registration  -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " - 


FD = "C:/Windows/Fonts/"


pdfmetrics.registerFont(TTFont("Arial",       FD + "arial.ttf"))


pdfmetrics.registerFont(TTFont("Arial-Bold",  FD + "arialbd.ttf"))


pdfmetrics.registerFont(TTFont("Arial-Italic",FD + "ariali.ttf"))


pdfmetrics.registerFont(TTFont("Arial-BI",    FD + "arialbi.ttf"))


pdfmetrics.registerFont(TTFont("Consolas",    FD + "consola.ttf"))


pdfmetrics.registerFont(TTFont("Consolas-Bold",FD + "consolab.ttf"))


pdfmetrics.registerFont(TTFont("Calibri",     FD + "calibri.ttf"))


pdfmetrics.registerFont(TTFont("Calibri-Bold",FD + "calibrib.ttf"))


pdfmetrics.registerFont(TTFont("Segoe",       FD + "segoeui.ttf"))


pdfmetrics.registerFont(TTFont("Segoe-Bold",  FD + "segoeuib.ttf"))





from reportlab.pdfbase.pdfmetrics import registerFontFamily


registerFontFamily("Arial",


    normal="Arial", bold="Arial-Bold",


    italic="Arial-Italic", boldItalic="Arial-BI")





#  -  - " - " -  Paths  -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " - 


ASSETS = r"C:\Users\Kala\.cursor\projects\c-CC-Project-SFDC-Snowflake\assets"


def asset(name): return os.path.join(ASSETS, name)





IMG_AUTH     = asset("c__Users_Kala_AppData_Roaming_Cursor_User_workspaceStorage_8db96b5896cf80549641b385b6149186_images_image-6ae83b32-501d-4810-8950-2396c20492cf.png")


IMG_NAMED_C  = asset("c__Users_Kala_AppData_Roaming_Cursor_User_workspaceStorage_8db96b5896cf80549641b385b6149186_images_image-51bbccd7-c10a-4dba-9824-4490b21c67f2.png")


IMG_EXT_DS   = asset("c__Users_Kala_AppData_Roaming_Cursor_User_workspaceStorage_8db96b5896cf80549641b385b6149186_images_image-0f691fbb-b7b9-4f01-a87c-8021567e1f24.png")


IMG2_AUTH    = asset("c__Users_Kala_AppData_Roaming_Cursor_User_workspaceStorage_8db96b5896cf80549641b385b6149186_images_image-790491e4-f0ee-4f4f-8f46-12550a6f0468.png")


IMG2_NAMED_C = asset("c__Users_Kala_AppData_Roaming_Cursor_User_workspaceStorage_8db96b5896cf80549641b385b6149186_images_image-668b5c31-e7ec-46b1-9e52-11a2799b26e6.png")


IMG2_DS_LIST = asset("c__Users_Kala_AppData_Roaming_Cursor_User_workspaceStorage_8db96b5896cf80549641b385b6149186_images_image-82ed5521-8078-47c6-b2da-b4aff1f0d948.png")


IMG2_EDIT_DS = asset("c__Users_Kala_AppData_Roaming_Cursor_User_workspaceStorage_8db96b5896cf80549641b385b6149186_images_image-91e25996-5efc-48c9-ba8d-922141a4dd01.png")


IMG2_MAPPING = asset("c__Users_Kala_AppData_Roaming_Cursor_User_workspaceStorage_8db96b5896cf80549641b385b6149186_images_image-095cfd52-ae4d-4d32-85f9-9c79e956736b.png")


IMG_GPTFY    = asset("c__Users_Kala_AppData_Roaming_Cursor_User_workspaceStorage_8db96b5896cf80549641b385b6149186_images_image-9c8b0d37-022c-4d7b-b3eb-7585c07ae082.png")





OUTPUT = r"C:\CC\Project_SFDC\Snowflake\SF_Snowflake_Guide_v2.pdf"





#  -  - " - " -  Colour Palette  -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " - " - 


C = {


    "navy":        colors.HexColor("#0A1628"),


    "blue_dark":   colors.HexColor("#0D47A1"),


    "blue_mid":    colors.HexColor("#1565C0"),


    "blue":        colors.HexColor("#1976D2"),


    "blue_light":  colors.HexColor("#BBDEFB"),


    "blue_xlight": colors.HexColor("#E3F2FD"),


    "snow":        colors.HexColor("#29B5E8"),   # Snowflake brand


    "sf":          colors.HexColor("#00A1E0"),   # Salesforce brand


    "green_dark":  colors.HexColor("#1B5E20"),


    "green":       colors.HexColor("#2E7D32"),


    "green_light": colors.HexColor("#E8F5E9"),


    "amber":       colors.HexColor("#FF8F00"),


    "amber_light": colors.HexColor("#FFF8E1"),


    "red_light":   colors.HexColor("#FFEBEE"),


    "red":         colors.HexColor("#C62828"),


    "purple":      colors.HexColor("#6A1B9A"),


    "purple_light":colors.HexColor("#F3E5F5"),


    "grey_xlight": colors.HexColor("#F8F9FA"),


    "grey_light":  colors.HexColor("#ECEFF1"),


    "grey_mid":    colors.HexColor("#B0BEC5"),


    "grey":        colors.HexColor("#607D8B"),


    "grey_dark":   colors.HexColor("#37474F"),


    "white":       colors.white,


    "code_bg":     colors.HexColor("#0D1117"),


    "code_fg":     colors.HexColor("#E6EDF3"),


    "code_kw":     colors.HexColor("#FF7B72"),


    "code_str":    colors.HexColor("#A5D6FF"),


    "code_border": colors.HexColor("#29B5E8"),


}





PAGE_W, PAGE_H = A4


LM = RM = 18 * mm


TM = 22 * mm


BM = 18 * mm


CW = PAGE_W - LM - RM   # content width = ~174mm





#  -  - " - " -  Paragraph Styles  -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " - " - 


def S(name, font="Arial", size=10, color=None, **kw):


    kw.setdefault("textColor", color or C["grey_dark"])


    return ParagraphStyle(name, fontName=font, fontSize=size, **kw)





body      = S("body",    size=9.5,  leading=15, spaceAfter=4,  alignment=TA_JUSTIFY)


body_b    = S("body_b",  font="Arial-Bold", size=9.5, leading=15, spaceAfter=4)


bullet    = S("bullet",  size=9.5,  leading=14, spaceAfter=3,  leftIndent=16, firstLineIndent=-10)


sub_blt   = S("sub_blt", size=9,    leading=13, spaceAfter=2,  leftIndent=30, firstLineIndent=-10,


               color=C["grey"])


sub_h     = S("sub_h",   font="Calibri-Bold", size=13.5, color=C["blue_dark"],


               spaceBefore=14, spaceAfter=2)


sub_h2    = S("sub_h2",  font="Calibri-Bold", size=11, color=C["blue_mid"],


               spaceBefore=8, spaceAfter=2)


code_st   = S("code",    font="Consolas", size=7.8, leading=11.5,


               textColor=C["code_fg"], backColor=C["code_bg"],


               leftIndent=10, rightIndent=10, spaceBefore=1, spaceAfter=1)


note_st   = S("note",    font="Arial-Italic", size=8.5, leading=13, color=C["grey"])


caption   = S("caption", font="Arial-Italic", size=8,  color=C["grey"],


               alignment=TA_CENTER, spaceBefore=3, spaceAfter=8)


toc_h     = S("toc_h",   font="Calibri-Bold", size=10.5, color=C["blue_dark"], leading=18)


toc_sub   = S("toc_sub", size=9.5, color=C["grey_dark"], leading=16)


cell_hdr  = S("cell_hdr",font="Arial-Bold", size=8.5, color=C["white"])


cell_body = S("cell_b",  size=8.5, leading=12)





#  -  - " - " -  Custom Flowables  -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " - " - 





class SectionBanner(Flowable):


    """Full-width gradient-style section header banner."""


    def __init__(self, number, title, c1, c2=None, width=CW):


        super().__init__()


        self.number = number


        self.title  = title


        self.c1     = c1


        self.c2     = c2 or c1


        self.width  = width


        self.height = 38





    def draw(self):


        c = self.canv


        h = self.height


        w = self.width


        # faux gradient: draw 40 thin rects fading c1 -  'c2


        steps = 40


        r1,g1,b1 = self.c1.red, self.c1.green, self.c1.blue


        r2,g2,b2 = self.c2.red, self.c2.green, self.c2.blue


        sw = w / steps


        for i in range(steps):


            t = i / steps


            rc = colors.Color(r1+(r2-r1)*t, g1+(g2-g1)*t, b1+(b2-b1)*t)


            c.setFillColor(rc)


            c.rect(i*sw, 0, sw+1, h, fill=1, stroke=0)


        # accent stripe bottom


        c.setFillColor(C["snow"])


        c.rect(0, 0, w, 3, fill=1, stroke=0)


        # text


        c.setFillColor(C["white"])


        c.setFont("Calibri-Bold", 15)


        c.drawString(14, 13, f"Section {self.number}  -  {self.title}")





    def wrap(self, *args):


        return self.width, self.height + 8








class AccentRule(Flowable):


    """A thin left-aligned coloured rule used under sub-headings."""


    def __init__(self, width=CW, color=None, thickness=1.5):


        super().__init__()


        self._w = width


        self.color = color or C["blue"]


        self.thickness = thickness





    def draw(self):


        c = self.canv


        c.setStrokeColor(self.color)


        c.setLineWidth(self.thickness)


        c.line(0, 0, self._w, 0)





    def wrap(self, *args):


        return self._w, 5








class CardBox(Flowable):


    """


    Rounded card with a coloured left accent border.


    icon_char: single char emoji/symbol shown in the accent bar.


    """


    def __init__(self, paragraphs, accent=None, bg=None,


                 icon="i", label="NOTE", width=CW, padding=10):


        super().__init__()


        self.paragraphs = paragraphs if isinstance(paragraphs, list) else [paragraphs]


        self.accent  = accent or C["blue"]


        self.bg      = bg or C["blue_xlight"]


        self.icon    = icon


        self.label   = label


        self.width   = width


        self.padding = padding


        self._height = 50





    def _est_height(self):


        total = self.padding


        for p in self.paragraphs:


            w, h = p.wrapOn(self.canv, self.width - 36 - self.padding, 999)


            total += h + 4


        return total + self.padding





    def draw(self):


        c = self.canv


        h = self._height


        w = self.width


        p = self.padding


        # background


        c.setFillColor(self.bg)


        c.roundRect(0, 0, w, h, 5, fill=1, stroke=0)


        # left accent bar


        c.setFillColor(self.accent)


        c.roundRect(0, 0, 6, h, 3, fill=1, stroke=0)


        # icon circle


        c.setFillColor(self.accent)


        c.circle(20, h - 16, 9, fill=1, stroke=0)


        c.setFillColor(C["white"])


        c.setFont("Arial-Bold", 8)


        c.drawCentredString(20, h - 19, self.icon)


        # label


        c.setFillColor(self.accent)


        c.setFont("Arial-Bold", 7.5)


        c.drawString(33, h - 19, self.label)


        # content


        y = h - p - 6


        for para in self.paragraphs:


            pw, ph = para.wrapOn(c, w - 36 - p, 999)


            y -= ph


            para.drawOn(c, 36, y)


            y -= 4





    def wrap(self, avail_w, avail_h):


        self._height = self._est_height()


        return self.width, self._height + 6








class StepCard(Flowable):


    """A numbered step with coloured circle and content block."""


    def __init__(self, number, heading, detail, accent=None, width=CW):


        super().__init__()


        self.number  = number


        self.heading = heading


        self.detail  = detail


        self.accent  = accent or C["snow"]


        self.width   = width


        self._height = 50





    def draw(self):


        c = self.canv


        h = self._height


        w = self.width


        # subtle bg


        c.setFillColor(C["grey_xlight"])


        c.roundRect(0, 0, w, h, 4, fill=1, stroke=0)


        # left accent


        c.setFillColor(self.accent)


        c.roundRect(0, 0, 4, h, 2, fill=1, stroke=0)


        # circle


        cx = 22


        c.setFillColor(self.accent)


        c.circle(cx, h - 18, 12, fill=1, stroke=0)


        c.setFillColor(C["white"])


        c.setFont("Calibri-Bold", 12)


        c.drawCentredString(cx, h - 22, str(self.number))


        # heading


        c.setFillColor(C["grey_dark"])


        c.setFont("Calibri-Bold", 10.5)


        c.drawString(44, h - 16, self.heading)


        # detail text


        detail_p = Paragraph(self.detail, S("_d", size=9, leading=13, color=C["grey_dark"]))


        dw, dh = detail_p.wrapOn(c, w - 50, 999)


        detail_p.drawOn(c, 44, h - 20 - dh - 4)





    def wrap(self, avail_w, avail_h):


        # estimate height from detail text


        test = Paragraph(self.detail, S("_dt", size=9, leading=13))


        _, dh = test.wrap(self.width - 50, 999)


        self._height = max(46, dh + 34)


        return self.width, self._height + 6








class ScreenshotLabel(Flowable):


    """A small header bar above a screenshot."""


    def __init__(self, text, width=CW, color=None):


        super().__init__()


        self.text  = text


        self._w    = width


        self.color = color or C["blue_mid"]





    def draw(self):


        c = self.canv


        c.setFillColor(self.color)


        c.roundRect(0, 0, self._w, 20, 3, fill=1, stroke=0)


        c.setFillColor(C["white"])


        c.setFont("Arial-Bold", 8)


        c.drawString(10, 6, self.text)





    def wrap(self, *args):


        return self._w, 22








class DotRule(Flowable):


    """Dotted separator line."""


    def __init__(self, width=CW, color=None):


        super().__init__()


        self._w = width


        self.color = color or C["grey_light"]





    def draw(self):


        c = self.canv


        c.setStrokeColor(self.color)


        c.setLineWidth(0.5)


        c.setDash(2, 4)


        c.line(0, 0, self._w, 0)


        c.setDash()





    def wrap(self, *args):


        return self._w, 8








#  -  - " - " -  Helper Functions  -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " - " - 





def embed_image(path, caption_text=None, width=CW, label=None, label_color=None):


    elems = []


    if label:


        elems.append(ScreenshotLabel(label, CW, label_color))


    if os.path.exists(path):


        from PIL import Image as PILImage


        with PILImage.open(path) as im:


            iw, ih = im.size


        aspect = ih / iw


        img_w  = min(width, CW)


        img_h  = img_w * aspect


        if img_h > 155 * mm:


            img_h = 155 * mm


            img_w = img_h / aspect


        # border around image


        img = Image(path, width=img_w, height=img_h, hAlign="CENTER")


        t = Table([[img]], colWidths=[CW])


        t.setStyle(TableStyle([


            ("BOX",           (0,0),(-1,-1), 0.5, C["grey_mid"]),


            ("BACKGROUND",    (0,0),(-1,-1), C["grey_xlight"]),


            ("TOPPADDING",    (0,0),(-1,-1), 4),


            ("BOTTOMPADDING", (0,0),(-1,-1), 4),


            ("LEFTPADDING",   (0,0),(-1,-1), 4),


            ("RIGHTPADDING",  (0,0),(-1,-1), 4),


        ]))


        elems.append(t)


    else:


        elems.append(Paragraph(f"[Image not found: {os.path.basename(path)}]", note_st))


    if caption_text:


        elems.append(Paragraph(caption_text, caption))


    return elems








def code_block(code_text, lang="sql"):


    """Dark terminal-style code block  -  splittable across pages."""


    badge_style = S(f"badge_{lang}", font="Consolas-Bold", size=7.5,


                    color=C["white"], backColor=C["code_bg"])





    class CodeHeader(Flowable):


        def __init__(self, label, width=CW):


            super().__init__()


            self._w = width


            self.label = label


        def draw(self):


            c = self.canv


            c.setFillColor(C["code_bg"])


            c.rect(0, 0, self._w, 18, fill=1, stroke=0)


            c.setFillColor(C["code_border"])


            c.roundRect(6, 3, 28, 12, 3, fill=1, stroke=0)


            c.setFillColor(C["code_bg"])


            c.setFont("Consolas-Bold", 7)


            c.drawCentredString(20, 6, self.label.upper())


            c.setStrokeColor(C["grey"])


            c.setLineWidth(0.4)


            c.line(0, 0, self._w, 0)


        def wrap(self, *a): return self._w, 20





    rows = []


    for line in code_text.split("\n"):


        rows.append([Paragraph(line if line.strip() else "\u00a0", code_st)])





    inner = Table(rows, colWidths=[CW - 2], splitByRow=1)


    inner.setStyle(TableStyle([


        ("BACKGROUND",    (0,0),(-1,-1), C["code_bg"]),


        ("TOPPADDING",    (0,0),(-1,-1), 1),


        ("BOTTOMPADDING", (0,0),(-1,-1), 1),


        ("LEFTPADDING",   (0,0),(-1,-1), 0),


        ("RIGHTPADDING",  (0,0),(-1,-1), 0),


    ]))





    class CodeWrapper(Flowable):


        """Wraps header + body with a border box, splittable."""


        def __init__(self, header, body_table, width=CW):


            super().__init__()


            self._hdr  = header


            self._body = body_table


            self._w    = width


            self._hh   = 20


            self._bh   = 0


        def wrap(self, aw, ah):


            _, self._hh  = self._hdr.wrap(aw, ah)


            _, self._bh  = self._body.wrap(aw - 2, ah)


            return self._w, self._hh + self._bh + 8


        def draw(self):


            c  = self.canv


            th = self._hh + self._bh + 8


            c.setFillColor(C["code_bg"])


            c.roundRect(0, 0, self._w, th, 5, fill=1, stroke=0)


            c.setStrokeColor(C["code_border"])


            c.setLineWidth(1)


            c.roundRect(0, 0, self._w, th, 5, fill=0, stroke=1)


            self._hdr.drawOn(c, 0, th - self._hh - 2)


            self._body.drawOn(c, 1, 4)


        def split(self, aw, ah):


            # Let inner table split naturally


            _, hh = self._hdr.wrap(aw, ah)


            if ah < hh + 20:


                return []


            parts = self._body.split(aw - 2, ah - hh - 12)


            if not parts:


                return []


            result = []


            result.append(CodeWrapper(self._hdr, parts[0], self._w))


            for p in parts[1:]:


                result.append(CodeWrapper(CodeHeader(lang), p, self._w))


            return result





    return CodeWrapper(CodeHeader(lang), inner, CW)








def kv_table(rows, col1=55*mm, accent=None):


    accent = accent or C["blue_dark"]


    col2 = CW - col1


    data = []


    for i, (k, v) in enumerate(rows):


        bg = C["grey_xlight"] if i % 2 == 0 else C["white"]


        data.append([


            Paragraph(f"<b>{k}</b>", S(f"_kh{i}", font="Arial-Bold", size=8.5, color=C["grey_dark"])),


            Paragraph(v, S(f"_kv{i}", size=8.5, color=C["grey_dark"], leading=13))


        ])


    t = Table(data, colWidths=[col1, col2])


    t.setStyle(TableStyle([


        ("ROWBACKGROUNDS",  (0,0),(-1,-1), [C["grey_xlight"], C["white"]]),


        ("LEFTPADDING",     (0,0),(-1,-1), 8),


        ("RIGHTPADDING",    (0,0),(-1,-1), 8),


        ("TOPPADDING",      (0,0),(-1,-1), 5),


        ("BOTTOMPADDING",   (0,0),(-1,-1), 5),


        ("GRID",            (0,0),(-1,-1), 0.3, C["grey_mid"]),


        ("LINEABOVE",       (0,0),(-1,0),  1.5, accent),


        ("VALIGN",          (0,0),(-1,-1), "MIDDLE"),


    ]))


    return t








def comparison_table(headers, rows, col_widths):


    data = [[Paragraph(f"<b>{h}</b>", cell_hdr) for h in headers]]


    for row in rows:


        data.append([Paragraph(str(v), cell_body) for v in row])


    t = Table(data, colWidths=col_widths)


    t.setStyle(TableStyle([


        ("BACKGROUND",    (0,0),(-1,0),  C["navy"]),


        ("TEXTCOLOR",     (0,0),(-1,0),  C["white"]),


        ("ROWBACKGROUNDS",(0,1),(-1,-1), [C["white"], C["grey_xlight"]]),


        ("GRID",          (0,0),(-1,-1), 0.3, C["grey_mid"]),


        ("LINEABOVE",     (0,0),(-1,0),  0, C["navy"]),


        ("TOPPADDING",    (0,0),(-1,-1), 5),


        ("BOTTOMPADDING", (0,0),(-1,-1), 5),


        ("LEFTPADDING",   (0,0),(-1,-1), 7),


        ("RIGHTPADDING",  (0,0),(-1,-1), 7),


        ("VALIGN",        (0,0),(-1,-1), "MIDDLE"),


        ("FONTSIZE",      (0,1),(-1,-1), 8.5),


    ]))


    return t








def note(text, accent=None, bg=None, icon="i", label="NOTE"):


    accent = accent or C["blue"]


    bg     = bg or C["blue_xlight"]


    para   = Paragraph(text, S("_np", size=8.8, leading=14, color=C["grey_dark"]))


    return CardBox(para, accent=accent, bg=bg, icon=icon, label=label, width=CW)








def warning(text):


    return note(text, accent=C["amber"], bg=C["amber_light"], icon="!", label="IMPORTANT")








def error_note(text):


    return note(text, accent=C["red"], bg=C["red_light"], icon=" - -", label="WARNING")








def step(number, heading, detail, accent=None):


    return StepCard(number, heading, detail, accent=accent, width=CW)








def sh(text, color=None):


    """Sub-heading with accent underline."""


    color = color or C["blue_dark"]


    return [Paragraph(text, sub_h), AccentRule(CW, color), Spacer(1, 3*mm)]








def sh2(text, color=None):


    return Paragraph(text, sub_h2)








#  -  - " - " -  Page Callbacks  -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " - " - 


_current_section = [""]





def header_footer(canvas, doc, section_label=""):


    canvas.saveState()


    # Header


    canvas.setFillColor(C["navy"])


    canvas.rect(0, PAGE_H - 12*mm, PAGE_W, 12*mm, fill=1, stroke=0)


    # snow accent strip


    canvas.setFillColor(C["snow"])


    canvas.rect(0, PAGE_H - 12*mm, 4, 12*mm, fill=1, stroke=0)


    canvas.setFillColor(C["white"])


    canvas.setFont("Arial-Bold", 7.5)


    canvas.drawString(LM + 6, PAGE_H - 7.5*mm, "Snowflake  -  Salesforce Integration Guide")


    canvas.setFont("Arial", 7)


    canvas.setFillColor(C["blue_light"])


    canvas.drawRightString(PAGE_W - RM, PAGE_H - 7.5*mm, "Internal Documentation  |  March 2026")





    # Footer


    canvas.setFillColor(C["grey_xlight"])


    canvas.rect(0, 0, PAGE_W, 9*mm, fill=1, stroke=0)


    canvas.setStrokeColor(C["grey_mid"])


    canvas.setLineWidth(0.5)


    canvas.line(LM, 9*mm, PAGE_W - RM, 9*mm)


    canvas.setFillColor(C["grey"])


    canvas.setFont("Arial", 7)


    canvas.drawString(LM, 3.2*mm, "Confidential - For Internal Use Only")


    # page number pill


    pg = str(doc.page)


    pw = canvas.stringWidth(pg, "Arial-Bold", 8) + 12


    px = (PAGE_W - pw) / 2


    canvas.setFillColor(C["blue_dark"])


    canvas.roundRect(px, 1.5*mm, pw, 6*mm, 3, fill=1, stroke=0)


    canvas.setFillColor(C["white"])


    canvas.setFont("Arial-Bold", 8)


    canvas.drawCentredString(PAGE_W / 2, 3.2*mm, pg)


    canvas.restoreState()








def cover_page_cb(canvas, doc):


    canvas.saveState()


    w, h = PAGE_W, PAGE_H


    # Deep navy background


    canvas.setFillColor(C["navy"])


    canvas.rect(0, 0, w, h, fill=1, stroke=0)


    # Gradient bands  (faux gradient navy  -  ' blue_dark)


    steps = 60


    for i in range(steps):


        t = i / steps


        r = C["navy"].red   + (C["blue_mid"].red   - C["navy"].red)   * t


        g = C["navy"].green + (C["blue_mid"].green  - C["navy"].green) * t


        b = C["navy"].blue  + (C["blue_mid"].blue   - C["navy"].blue)  * t


        canvas.setFillColor(colors.Color(r, g, b))


        canvas.rect(0, (i/steps)*h*0.55, w, h*0.55/steps + 1, fill=1, stroke=0)


    # large decorative circle top-right


    canvas.setFillColor(colors.Color(0.07, 0.18, 0.42, alpha=0.5))


    canvas.circle(w + 30, h - 20, 130, fill=1, stroke=0)


    canvas.setFillColor(colors.Color(0.1, 0.25, 0.55, alpha=0.35))


    canvas.circle(w - 20, h + 30, 100, fill=1, stroke=0)


    # bottom decorative circle


    canvas.setFillColor(colors.Color(0.05, 0.12, 0.35, alpha=0.5))


    canvas.circle(-40, -30, 120, fill=1, stroke=0)


    # GPTfy logo  -  prominent top-centre on a solid white card


    logo_h = 22 * mm


    logo_w = logo_h * 3.6


    logo_x = (w - logo_w) / 2


    logo_y = h * 0.60


    card_pad = 10


    card_x = logo_x - card_pad


    card_y = logo_y - card_pad


    card_w = logo_w + card_pad * 2


    card_h = logo_h + card_pad * 2


    # Solid white card so purple logo is fully visible on dark background


    canvas.setFillColor(C["white"])


    canvas.roundRect(card_x, card_y, card_w, card_h, 8, fill=1, stroke=0)


    canvas.setStrokeColor(C["snow"])


    canvas.setLineWidth(1.5)


    canvas.roundRect(card_x, card_y, card_w, card_h, 8, fill=0, stroke=1)


    if os.path.exists(IMG_GPTFY):


        canvas.drawImage(IMG_GPTFY, logo_x, logo_y,


                         width=logo_w, height=logo_h,


                         mask="auto", preserveAspectRatio=True)


    canvas.setFillColor(C["grey_mid"])


    canvas.setFont("Arial", 7.5)


    canvas.drawCentredString(w/2, card_y + card_h + 5, "Powered by")


    # Main title block


    canvas.setFillColor(C["white"])


    canvas.setFont("Calibri-Bold", 30)


    canvas.drawCentredString(w/2, h * 0.49, "Snowflake  x  Salesforce")


    canvas.setFont("Calibri-Bold", 20)


    canvas.setFillColor(C["blue_light"])


    canvas.drawCentredString(w/2, h * 0.44, "Integration Guide")


    # Accent lines


    canvas.setStrokeColor(C["snow"])


    canvas.setLineWidth(1.5)


    canvas.line(LM, h * 0.38, w - RM, h * 0.38)


    canvas.setStrokeColor(C["sf"])


    canvas.setLineWidth(0.7)


    canvas.line(LM, h * 0.38 - 5, w - RM, h * 0.38 - 5)


    # Subtitle bar


    canvas.setFillColor(colors.Color(0, 0, 0, alpha=0.25))


    canvas.roundRect(LM, h * 0.38 + 12, w - LM - RM, 42, 5, fill=1, stroke=0)


    canvas.setFillColor(C["white"])


    canvas.setFont("Arial", 10)


    canvas.drawCentredString(w/2, h * 0.38 + 36, "Connecting Snowflake with Salesforce via")


    canvas.setFont("Arial-Bold", 10)


    canvas.drawCentredString(w/2, h * 0.38 + 22, "External Data Source  &  GPTfy API Data Source")


    # Bottom meta


    canvas.setFillColor(C["grey_mid"])


    canvas.setFont("Arial", 8)


    canvas.drawCentredString(w/2, 28*mm, "March 2026  -  Internal Technical Documentation  -  Confidential")


    # Bottom accent bar


    canvas.setFillColor(C["snow"])


    canvas.rect(0, 0, w, 6, fill=1, stroke=0)


    canvas.restoreState()








#  -  - " - " -  Cover  -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " - 


def build_cover():


    return [Spacer(1, 1), PageBreak()]   # content drawn entirely via cover_page_cb








#  -  - " - " -  Table of Contents  -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " - 


def build_toc():


    el = []


    el.append(Spacer(1, 4*mm))


    el.append(Paragraph("Table of Contents", S("toch", font="Calibri-Bold", size=18,


                         color=C["navy"], spaceAfter=2)))


    el.append(AccentRule(CW, C["snow"], 2))


    el.append(Spacer(1, 4*mm))





    sections = [


        (True,  "1",   "Connecting Snowflake with Salesforce via External Data Source"),


        (False, "1.1", "Pre-Requisites"),


        (False, "1.2", "Snowflake Setup  -  Security Integration & OAuth"),


        (False, "1.3", "Snowflake Setup  -  Database, Tables & Data"),


        (False, "1.4", "Salesforce Setup  -  Auth Provider"),


        (False, "1.5", "Salesforce Setup  -  Named Credential (Legacy)"),


        (False, "1.6", "Salesforce Setup  -  External Data Source"),


        (False, "1.7", "Sync External Objects"),


        (False, "1.8", "Configure External Objects in Salesforce"),


        (False, "1.9", "Architecture Overview"),


        (True,  "2",   "Connecting Snowflake with Salesforce via GPTfy API Data Source"),


        (False, "2.1", "Pre-Requisites"),


        (False, "2.2", "Salesforce Setup  -  Auth Provider (SnowflakeDS)"),


        (False, "2.3", "Salesforce Setup  -  Named Credential (SnowflakeDS)"),


        (False, "2.4", "Apex Connector Class  -  SampleDataSourceClass2"),


        (False, "2.5", "GPTfy Setup  -  Create API Data Source"),


        (False, "2.6", "GPTfy Setup  -  Prompt with API Data Source Mapping"),


        (False, "2.7", "Comparison  -  External Data Source vs GPTfy API Data Source"),


    ]


    rows = []


    for is_section, num, title in sections:


        st = toc_h if is_section else toc_sub


        bg = C["blue_xlight"] if is_section else C["white"]


        rows.append([


            Paragraph(f"<b>{num}</b>" if is_section else num, st),


            Paragraph(f"<b>{title}</b>" if is_section else title, st),


            Paragraph("", st)


        ])


    widths = [18*mm, CW - 18*mm - 6*mm, 6*mm]


    t = Table(rows, colWidths=widths)


    row_bgs = []


    for i, (is_s, _, _) in enumerate(sections):


        row_bgs.append(C["blue_xlight"] if is_s else (C["white"] if i%2==0 else C["grey_xlight"]))





    style_cmds = [


        ("TOPPADDING",    (0,0),(-1,-1), 5),


        ("BOTTOMPADDING", (0,0),(-1,-1), 5),


        ("LEFTPADDING",   (0,0),(-1,-1), 8),


        ("RIGHTPADDING",  (0,0),(-1,-1), 8),


        ("LINEBELOW",     (0,-1),(-1,-1), 0.5, C["grey_mid"]),


        ("VALIGN",        (0,0),(-1,-1), "MIDDLE"),


    ]


    for i, (is_s, _, _) in enumerate(sections):


        bg = C["blue_xlight"] if is_s else (C["white"] if i%2==0 else C["grey_xlight"])


        style_cmds.append(("BACKGROUND", (0,i),(-1,i), bg))


        if is_s:


            style_cmds.append(("LINEABOVE", (0,i),(-1,i), 1, C["blue_mid"]))


    t.setStyle(TableStyle(style_cmds))


    el.append(t)


    el.append(PageBreak())


    return el








#  -  - " - " -  Section 1  -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " - 


def build_section1():


    el = []


    el.append(SectionBanner(1,


        "Connecting Snowflake with Salesforce via External Data Source",


        C["blue_dark"], C["blue_mid"]))


    el.append(Spacer(1, 5*mm))


    el.append(Paragraph(


        "This section provides a complete step-by-step walkthrough for establishing a "


        "live bi-directional connection between a <b>Snowflake</b> database and a "


        "<b>Salesforce</b> org using Salesforce's native <b>External Data Source</b> "


        "(Salesforce Connect  -  SQL type). Snowflake tables appear as <b>External Objects</b> "


        "inside Salesforce, enabling real-time data access without ETL pipelines or "


        "data duplication.", body))


    el.append(Spacer(1, 4*mm))





    # 1.1


    el += sh("1.1  Pre-Requisites")


    pre = [


        ("Snowflake Account",               "Admin-level access with the ability to create security integrations."),


        ("Salesforce Org with Connect",      "Active Salesforce Connect licence (External Data Sources  -  SQL type)."),


        ("GPTfy Installed",                  "GPTfy package installed in the Salesforce org."),


        ("Network Connectivity",             "Salesforce IP ranges must be allowlisted in Snowflake's network policy."),


    ]


    for title, detail in pre:


        el.append(Paragraph(f"<b>-  {title}</b>", bullet))


        el.append(Paragraph(detail, sub_blt))


    el.append(Spacer(1, 4*mm))





    # 1.2


    el += sh("1.2  Snowflake Setup  -  Security Integration & OAuth")


    el.append(Paragraph(


        "Salesforce uses <b>OAuth 2.0</b> to authenticate against Snowflake's REST API. "


        "Create a <b>Security Integration</b> in Snowflake that registers Salesforce as a "


        "trusted OAuth client and specifies the callback URL.", body))


    el.append(Spacer(1, 2*mm))


    el.append(code_block("""\


-- Step 1: Create the OAuth Security Integration


Create OR replace SECURITY INTEGRATION MY_SNOWSQL_CLIENT_DEVORG


TYPE = OAUTH


ENABLED = TRUE


OAUTH_CLIENT = CUSTOM


OAUTH_CLIENT_TYPE = 'CONFIDENTIAL'


OAUTH_REDIRECT_URI = 'https://<your-sf-domain>.my.salesforce.com/services/authcallback/Snowflake'


OAUTH_ISSUE_REFRESH_TOKENS = TRUE


OAUTH_REFRESH_TOKEN_VALIDITY = 7776000


;





-- Step 2: Describe integration  -  ' retrieve Consumer Key & Endpoint URLs


DESC SECURITY INTEGRATION MY_SNOWSQL_CLIENT_DEVORG;





-- Step 3: Retrieve the Consumer Secret


select SYSTEM$SHOW_OAUTH_CLIENT_SECRETS( 'MY_SNOWSQL_CLIENT_DEVORG' );""", "sql"))


    el.append(Spacer(1, 3*mm))


    for i, (h, d) in enumerate([


        ("Replace the integration name", "Change MY_SNOWSQL_CLIENT_DEVORG in all three commands to a unique name for your environment."),


        ("Set redirect URI",  "Replace the placeholder domain with your Salesforce My Domain. The suffix /services/authcallback/Snowflake must match the Auth Provider URL Suffix."),


        ("Run lines 1 - 9",    "Select lines 1 - 9 and click Run. The security integration is created."),


        ("Run DESC command", "Copy OAUTH_AUTHORIZATION_ENDPOINT, OAUTH_TOKEN_ENDPOINT, and OAUTH_CLIENT_ID from the output."),


        ("Run SHOW_SECRETS", "Copy OAUTH_CLIENT_SECRET from the JSON output."),


        ("Update callback",  "After saving the Salesforce Auth Provider, Salesforce generates a callback URL. Update the OAUTH_REDIRECT_URI in Snowflake if it differs, then re-run steps 3 - 5."),


    ], 1):


        el.append(step(i, h, d, C["snow"]))


    el.append(Spacer(1, 4*mm))





    # 1.3


    el += sh("1.3  Snowflake Setup  -  Database, Tables & Sample Data")


    el.append(Paragraph(


        "Create the database, schema, and tables that will be surfaced as External Objects. "


        "The <b>EXTERNALID</b> column enables Salesforce record linkage.", body))


    el.append(Spacer(1, 2*mm))


    el.append(code_block("""\


-- 1. Database and schema


CREATE DATABASE TESTDB;


CREATE SCHEMA TESTDB.MYSCHEMA;





-- 2. Department table


CREATE OR REPLACE TABLE TESTDB.MYSCHEMA.DEPARTMENT (


    DID            NUMBER(38,0)   NOT NULL,


    DEPARTMENTNAME VARCHAR(25)    NOT NULL,


    LOCATION       VARCHAR(25),


    CREATEDDATE    DATE           DEFAULT CURRENT_DATE(),


    EXTERNALID     VARCHAR(255),


    UNIQUE (DID)


);





-- 3. Employee table (FK  -  ' Department)


--    Note: DEPARTMENT_ID has no UNIQUE constraint  -  many employees can share a department


CREATE OR REPLACE TABLE TESTDB.MYSCHEMA.EMPLOYEE (


    EID            NUMBER         NOT NULL UNIQUE,


    EMPLOYEENAME   VARCHAR(25)    NOT NULL,


    EMAIL          VARCHAR(25)    DEFAULT NULL,


    JOBTITLE       VARCHAR(25)    DEFAULT NULL,


    DEPARTMENT_ID  NUMBER         NOT NULL,


    CREATEDDATE    DATE           DEFAULT CURRENT_DATE()


);


ALTER TABLE TESTDB.MYSCHEMA.EMPLOYEE


  ADD FOREIGN KEY (DEPARTMENT_ID) REFERENCES TESTDB.MYSCHEMA.DEPARTMENT(DID);





-- 4. Seed data  -  Department


INSERT INTO TESTDB.MYSCHEMA.DEPARTMENT (DID, DEPARTMENTNAME, LOCATION) VALUES


    (101,'Sales','Floor 1'),(102,'Marketing','Floor 3'),


    (103,'Engineering','Floor 7'),(104,'Customer Service','Floor 2'),


    (105,'Finance','Floor 4');


INSERT INTO TESTDB.MYSCHEMA.DEPARTMENT (DID,DEPARTMENTNAME,LOCATION,EXTERNALID)


    VALUES (106,'Finance','Floor 5','0018d00000eE0CFAA0');





-- 5. Seed data  -  Employee


INSERT INTO TESTDB.MYSCHEMA.EMPLOYEE (EID,EMPLOYEENAME,EMAIL,JOBTITLE,DEPARTMENT_ID) VALUES


    (201,'TestName1','testName1@test.com','Software Engineer',103),


    (202,'TestName2','testName2@test.com','Marketing Manager',102),


    (203,'TestName3','testName3@test.com','Finance',105),


    (204,'TestName4','testName4@test.com','Customer Service',104),


    (205,'TestName5','testName5@test.com','Software Engineer',103),


    (206,'TestName6','testName6@test.com','Marketing Manager',102),


    (207,'TestName7','testName7@test.com','Salesman',101);





-- 6. Verify


SELECT * FROM TESTDB.MYSCHEMA.DEPARTMENT;


SELECT t1.EID,t1.EMPLOYEENAME,t2.DEPARTMENTNAME


  FROM TESTDB.MYSCHEMA.EMPLOYEE t1


  INNER JOIN TESTDB.MYSCHEMA.DEPARTMENT t2 ON t1.DEPARTMENT_ID = t2.DID


  LIMIT 100;


SELECT * FROM TESTDB.MYSCHEMA.DEPARTMENT WHERE EXTERNALID='0018d00000eE0CFAA0';""", "sql"))


    el.append(Spacer(1, 2*mm))


    el.append(note(


        "The EXTERNALID column on DEPARTMENT stores the Salesforce record ID (e.g. an Account Id). "


        "This is the key linkage field  -  Salesforce queries filter by this value at runtime. "


        "Ensure DEPARTMENT_ID on EMPLOYEE has no UNIQUE constraint so multiple employees "


        "can belong to the same department.",


        C["blue"], C["blue_xlight"]))


    el.append(Spacer(1, 4*mm))





    # 1.4


    el += sh("1.4  Salesforce Setup  -  Auth Provider")


    el.append(Paragraph(


        "The Auth Provider stores the OAuth 2.0 credentials from Snowflake and "


        "handles token exchange. <b>Navigation:</b> Setup  -  ' Identity  -  ' Auth. Providers  -  ' New", body))


    el.append(Spacer(1, 2*mm))


    el.append(kv_table([


        ("Provider Type",           "Open ID Connect"),


        ("Name",                    "Snowflake"),


        ("URL Suffix",              "Snowflake  (auto-filled)"),


        ("Consumer Key",            "From DESC SECURITY INTEGRATION  -  ' OAUTH_CLIENT_ID"),


        ("Consumer Secret",         "From SYSTEM$SHOW_OAUTH_CLIENT_SECRETS"),


        ("Authorize Endpoint URL",  "https://&lt;account&gt;.snowflakecomputing.com/oauth/authorize"),


        ("Token Endpoint URL",      "https://&lt;account&gt;.snowflakecomputing.com/oauth/token-request"),


        ("Use PKCE Extension",      " -  Checked"),


        ("Send access token in header",  " -  Checked"),


        ("Include Consumer Secret in SOAP API", " -  Checked"),


    ]))


    el.append(Spacer(1, 3*mm))


    el += embed_image(IMG_AUTH,


        label="Screenshot  -  Auth Provider Configuration",


        caption_text="Figure 1.4  -  Salesforce Auth Provider 'Snowflake' (OpenID Connect)")


    el.append(Spacer(1, 2*mm))


    el.append(warning(


        "After saving, Salesforce generates a Callback URL at the bottom of the Auth Provider page. "


        "Copy this URL and update your Snowflake Security Integration's OAUTH_REDIRECT_URI to match, "


        "then re-run DESC and SHOW_SECRETS to refresh the credentials."))


    el.append(Spacer(1, 4*mm))





    # 1.5


    el += sh("1.5  Salesforce Setup  -  Named Credential (Legacy)")


    el.append(Paragraph(


        "Stores the Snowflake REST API endpoint and references the Auth Provider for OAuth token management. "


        "Use the <b>Legacy</b> type. <b>Navigation:</b> Setup  -  ' Security  -  ' Named Credentials  -  ' New Legacy", body))


    el.append(Spacer(1, 2*mm))


    el.append(kv_table([


        ("Label",                   "Snowflake"),


        ("Name",                    "Snowflake"),


        ("URL",                     "https://&lt;account&gt;.snowflakecomputing.com/api/v2/statements"),


        ("Identity Type",           "Named Principal"),


        ("Authentication Protocol", "OAuth 2.0"),


        ("Authentication Provider", "Snowflake  (Auth Provider created above)"),


        ("Generate Authorization Header",      " -  Checked"),


        ("Allow Merge Fields in HTTP Header",  " -  Checked"),


    ]))


    el.append(Spacer(1, 3*mm))


    el += embed_image(IMG_NAMED_C,


        label="Screenshot  -  Named Credential Configuration",


        caption_text="Figure 1.5  -  Named Credential 'Snowflake'  -  OAuth 2.0  -  Status: Authenticated")


    el.append(Spacer(1, 4*mm))





    # 1.6


    el += sh("1.6  Salesforce Setup  -  External Data Source")


    el.append(Paragraph(


        "The External Data Source is the Salesforce Connect configuration that maps Snowflake "


        "as a SQL-based external system. <b>Navigation:</b> Setup  -  ' Integrations  -  ' External Data Sources  -  ' New", body))


    el.append(Spacer(1, 2*mm))


    el.append(kv_table([


        ("External Data Source (Label)", "testSnowflake"),


        ("Name",                         "testSnowflake"),


        ("Type",                         "SQL"),


        ("Provider",                     "Snowflake"),


        ("Named Credential",             "Snowflake  (created in Step 1.5)"),


        ("Connection Timeout (Seconds)", "120"),


        ("Writable External Objects",    " -  Checked  -  enables DML from Salesforce"),


        ("Server Driven Pagination",     " -  Checked  -  improves performance with large datasets"),


    ]))


    el.append(Spacer(1, 3*mm))


    el += embed_image(IMG_EXT_DS,


        label="Screenshot  -  External Data Source Configuration",


        caption_text="Figure 1.6  -  External Data Source 'testSnowflake'  -  SQL Type with Snowflake Provider")


    el.append(Spacer(1, 4*mm))





    # 1.7


    el += sh("1.7  Sync External Objects")


    el.append(Paragraph(


        "After saving the External Data Source, synchronise with Snowflake to import table "


        "metadata as External Objects.", body))


    el.append(Spacer(1, 2*mm))


    for i, (h, d) in enumerate([


        ("Click 'Validate and Sync'",


         "From the External Data Source detail page, click Validate and Sync."),


        ("Enter connection parameters",


         "Database = TESTDB   |   Schema = MYSCHEMA"),


        ("Select objects",


         "Select DEPARTMENT and EMPLOYEE. Do NOT check 'Sync in Background'  -  run synchronously."),


        ("Verify deployment",


         "Go to Setup  -  ' External Objects. If Not Deployed, click Edit on each and check the Deployed checkbox."),


        ("Create tabs",


         "Create Salesforce App tabs for both External Objects via Setup  -  ' User Interface  -  ' Tabs  -  ' New."),


        ("Add related list",


         "Open a Department record. If the Employee related list is missing, add it via Page Layouts in Setup."),


    ], 1):


        el.append(step(i, h, d, C["sf"]))


    el.append(Spacer(1, 2*mm))


    el.append(error_note(


        "If sync fails with an authentication error, ensure the Named Credential status is 'Authenticated'. "


        "Click 'Authenticate' on the Named Credential to trigger the OAuth flow."))


    el.append(Spacer(1, 2*mm))


    el.append(note(


        "After sync, External Objects are named with the '__x' suffix in Salesforce "


        "(e.g. DEPARTMENT__x, EMPLOYEE__x). These are virtual  -  no data is stored in Salesforce. "


        "Every SOQL query or page load fires a live callout to Snowflake via the Named Credential.",


        C["blue"], C["blue_xlight"]))


    el.append(Spacer(1, 4*mm))





    # 1.8


    el += sh("1.8  Configure External Objects in Salesforce")


    for title, detail in [


        ("Record pages",   "Use Lightning App Builder to add External Object related lists to standard object pages."),


        ("GPTfy prompts",  "Create a GPTfy prompt on the Department External Object. Add Employee as a related object in prompt field mapping."),


        ("Run the prompt", "Navigate to a Department record  -  ' add GPTfy Console  -  ' run the prompt to verify end-to-end flow."),


        ("SOQL queries",   "External Objects support SOQL (with limitations): SELECT Id, DepartmentName__c FROM Department__x LIMIT 10"),


        ("DML operations", "Writable External Objects enabled: users can insert, update, delete Snowflake rows directly from Salesforce UI or Apex."),


    ]:


        el.append(Paragraph(f"<b>&gt;  {title}</b>", bullet))


        el.append(Paragraph(detail, sub_blt))


    el.append(Spacer(1, 4*mm))





    # 1.9 Architecture


    el += sh("1.9  Architecture Overview")


    el.append(comparison_table(


        ["Layer", "Component", "Purpose"],


        [


            ["Snowflake", "Security Integration (OAuth)", "Issues access/refresh tokens to Salesforce"],


            ["Snowflake", "TESTDB.MYSCHEMA tables", "Source data: DEPARTMENT, EMPLOYEE"],


            ["Salesforce", "Auth Provider (OpenID Connect)", "Manages OAuth token lifecycle"],


            ["Salesforce", "Named Credential", "Stores endpoint URL + auth reference"],


            ["Salesforce", "External Data Source (SQL/Snowflake)", "Salesforce Connect adapter"],


            ["Salesforce", "External Objects (DEPARTMENT__x, EMPLOYEE__x)", "Virtual SF objects backed by Snowflake"],


        ],


        [32*mm, 64*mm, CW - 96*mm]


    ))


    el.append(PageBreak())


    return el








#  -  - " - " -  Section 2  -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " - 


def build_section2():


    el = []


    el.append(SectionBanner(2,


        "Connecting Snowflake with Salesforce via GPTfy API Data Source",


        C["green_dark"], C["green"]))


    el.append(Spacer(1, 5*mm))


    el.append(Paragraph(


        "GPTfy's <b>API Data Source</b> is an alternative integration pattern that bypasses "


        "Salesforce Connect entirely. Instead of syncing External Objects, GPTfy calls "


        "Snowflake's REST API directly at <b>prompt runtime</b> via an Apex connector class. "


        "This gives you full control over the SQL query, data shaping, and callout timing  -  "


        "with no Salesforce Connect licence required.", body))


    el.append(Spacer(1, 2*mm))


    el.append(note(


        "The Snowflake database setup (TESTDB, MYSCHEMA, DEPARTMENT, EMPLOYEE and Security "


        "Integration) is IDENTICAL to Section 1. No additional Snowflake-side setup is needed. "


        "Start directly from Section 2.2.",


        C["green"], C["green_light"], icon="-", label="REUSE"))


    el.append(Spacer(1, 4*mm))





    # 2.1


    el += sh("2.1  Pre-Requisites", C["green_dark"])


    for title, detail in [


        ("Section 1 Snowflake setup complete", "Security Integration, TESTDB, MYSCHEMA, DEPARTMENT & EMPLOYEE must exist."),


        ("GPTfy installed",                    "GPTfy package deployed and active in the Salesforce org."),


        ("Apex deploy access",                 "Developer Console or VS Code with SFDX to deploy the connector class."),


        ("No Salesforce Connect licence",      "The API Data Source uses standard HTTP callouts  -  no SF Connect licence needed."),


    ]:


        el.append(Paragraph(f"<b>-  {title}</b>", bullet))


        el.append(Paragraph(detail, sub_blt))


    el.append(Spacer(1, 4*mm))





    # 2.2


    el += sh("2.2  Salesforce Setup  -  Auth Provider (SnowflakeDS)", C["green_dark"])


    el.append(Paragraph(


        "Follow the same steps as <b>Section 1.4</b>, but use <b>SnowflakeDS</b> as the name "


        "to keep this credential separate from the External Data Source one. "


        "<b>Navigation:</b> Setup  -  ' Identity  -  ' Auth. Providers  -  ' New", body))


    el.append(Spacer(1, 2*mm))


    el.append(kv_table([


        ("Provider Type",           "Open ID Connect"),


        ("Name",                    "SnowflakeDS"),


        ("URL Suffix",              "SnowflakeDS  (auto-filled)"),


        ("Consumer Key",            "From DESC SECURITY INTEGRATION  -  ' OAUTH_CLIENT_ID"),


        ("Consumer Secret",         "From SYSTEM$SHOW_OAUTH_CLIENT_SECRETS"),


        ("Authorize Endpoint URL",  "https://st81340.ap-southeast-1.snowflakecomputing.com/oauth/authorize"),


        ("Token Endpoint URL",      "https://st81340.ap-southeast-1.snowflakecomputing.com/oauth/token-request"),


        ("Use PKCE Extension",      " -  Checked"),


        ("Send access token in header",  " -  Checked"),


        ("Include Consumer Secret in SOAP API", " -  Checked"),


    ], accent=C["green_dark"]))


    el.append(Spacer(1, 3*mm))


    el += embed_image(IMG2_AUTH,


        label="Screenshot  -  Auth Provider (SnowflakeDS)",


        label_color=C["green_dark"],


        caption_text="Figure 2.2  -  Auth Provider 'SnowflakeDS'  -  OpenID Connect  -  ap-southeast-1 Snowflake account")


    el.append(Spacer(1, 2*mm))


    el.append(warning(


        "CRITICAL  -  The Snowflake Security Integration's OAUTH_REDIRECT_URI for this credential "


        "MUST end with /services/authcallback/SnowflakeDS (matching the URL Suffix 'SnowflakeDS'), "


        "NOT /Snowflake. These are two separate Auth Providers requiring two separate Security Integrations "


        "in Snowflake. Reusing the same integration will cause authentication failures."))


    el.append(Spacer(1, 4*mm))





    # 2.3


    el += sh("2.3  Salesforce Setup  -  Named Credential (SnowflakeDS)", C["green_dark"])


    el.append(Paragraph(


        "<b>Navigation:</b> Setup  -  ' Security  -  ' Named Credentials  -  ' New Legacy", body))


    el.append(Spacer(1, 2*mm))


    el.append(kv_table([


        ("Label",                   "SnowflakeDS"),


        ("Name",                    "SnowflakeDS"),


        ("URL",                     "https://st81340.ap-southeast-1.snowflakecomputing.com/api/v2/statements"),


        ("Identity Type",           "Named Principal"),


        ("Authentication Protocol", "OAuth 2.0"),


        ("Authentication Provider", "SnowflakeDS  (Auth Provider created above)"),


        ("Authentication Status",   "Authenticated"),


        ("Start Auth Flow on Save", " -  Checked"),


        ("Generate Authorization Header",      " -  Checked"),


        ("Allow Merge Fields in HTTP Header",  " -  -  Unchecked"),


        ("Allow Merge Fields in HTTP Body",    " -  -  Unchecked"),


    ], accent=C["green_dark"]))


    el.append(Spacer(1, 2*mm))


    el.append(note(


        "The Named Credential name 'SnowflakeDS' is referenced inside the Apex class via "


        "callout:SnowflakeDS (resolved from dataSource.Named_Credential__c). "


        "Ensure names match exactly.",


        C["green"], C["green_light"]))


    el.append(Spacer(1, 3*mm))


    el += embed_image(IMG2_NAMED_C,


        label="Screenshot  -  Named Credential (SnowflakeDS)",


        label_color=C["green_dark"],


        caption_text="Figure 2.3  -  Named Credential 'SnowflakeDS'  -  OAuth 2.0  -  Status: Authenticated")


    el.append(Spacer(1, 4*mm))





    # 2.4


    el += sh("2.4  Apex Connector Class  -  SampleDataSourceClass2", C["green_dark"])


    el.append(Paragraph(


        "This global Apex class implements GPTfy's <b>ccai.AIDataSourceInterface</b> "


        "(from the <b>ccai</b> managed package namespace). At prompt runtime GPTfy calls "


        "<font face='Consolas' size='8'>getExternalData()</font>, which fires a POST to "


        "Snowflake's SQL REST API and returns the result set. "


        "<b>Deploy this class before creating the API Data Source.</b>", body))


    el.append(Spacer(1, 2*mm))


    el.append(code_block("""\


global class SampleDataSourceClass2 implements ccai.AIDataSourceInterface {





    global String getExternalData(ccai__AI_Data_Source__c dataSource, String extractedData) {





      /*  Map<String, Object> maps = (Map<String, Object>)JSON.deserializeUntyped(extractedData);


          maps.put('Industry', 'Agriculture');


          return JSON.serialize(maps); */





        Map<String, Object> maps =


            (Map<String, Object>)JSON.deserializeUntyped(extractedData);


        System.debug('extractedData : ' + maps.get('Id'));





        HttpRequest req = new HttpRequest();


        req.setEndpoint('callout:' + dataSource.ccai__Named_Credential__c);


        req.setMethod('POST');


        req.setHeader('Content-Type', 'application/json');


        req.setHeader('Accept', 'application/json');


        req.setTimeout(60000);





        String sql =


            'SELECT t1.EID,t1.EmployeeName, t1.Email,t2.did, t2.departmentname ' +


            'FROM TESTDB.myschema.Employee as t1 ' +


            'INNER JOIN TESTDB.myschema.Department t2 ' +


            '    ON t1.department_id = t2.did ' +


            'WHERE t2.ExternalId = \\'' + maps.get('Id') + '\\'';





        Map<String, Object> body = new Map<String, Object>{


            'statement' => sql,


            'timeout'   => 60,


            'warehouse' => 'COMPUTE_WH',


            'database'  => 'TESTDB',


            'schema'    => 'MYSCHEMA',


            'role'      => 'SYSADMIN'


        };


        req.setBody(JSON.serialize(body));





        Http http = new Http();


        HttpResponse res = http.send(req);





        if (res.getStatusCode() == 200) {


            // Parse response: res.getBody() contains JSON with 'resultSet' for data


            Map<String, Object> response =


                (Map<String, Object>) JSON.deserializeUntyped(res.getBody());


            Object o = (Object) response.get('data');


            System.debug('Query Result: ' + o);


            return o.toString();


        } else {


            System.debug('Error: ' + res.getStatusCode() + ' - ' + res.getBody());


            return 'Error: ' + res.getStatusCode() + ' - ' + res.getBody();


        }


    }


}""", "apex"))


    el.append(Spacer(1, 3*mm))


    el.append(sh2("Class key points:"))


    el.append(Spacer(1, 1*mm))


    el.append(kv_table([


        ("Interface",               "ccai.AIDataSourceInterface  -  from the ccai (GPTfy) managed package namespace"),


        ("Parameter type",          "ccai__AI_Data_Source__c  -  namespaced custom object from the ccai managed package"),


        ("extractedData",           "JSON of the current Salesforce record context. GPTfy passes this automatically at runtime."),


        ("ccai__Named_Credential__c","Namespaced field on ccai__AI_Data_Source__c  -  resolves to 'SnowflakeDS' at runtime"),


        ("Remote Site Settings",    "NOT required. Named Credentials automatically whitelist the endpoint for Apex callouts."),


        ("SQL filter",              "Joins EMPLOYEE and DEPARTMENT filtered by DEPARTMENT.ExternalId = current SF record Id"),


        ("Snowflake endpoint",      "POST /api/v2/statements  -  Snowflake SQL API v2, returns data array as JSON"),


        ("Return value",            "The data array from Snowflake, injected into the GPTfy prompt as enriched context"),


        ("Security note",           "The Id value comes from Salesforce's system-generated 18-char record Id  -  safe for SQL concatenation."),


    ], col1=48*mm, accent=C["green_dark"]))


    el.append(Spacer(1, 4*mm))





    # 2.5


    el += sh("2.5  GPTfy Setup  -  Create API Data Source", C["green_dark"])


    el.append(Paragraph(


        "<b>Navigation:</b> GPTfy  -  ' API Data Source  -  ' New", body))


    el.append(Spacer(1, 2*mm))


    el.append(Paragraph(


        "The GPTfy API Data Source catalogue lists all available connectors. "


        "Select <b>Snowflake API</b> or create a <b>Test API Data Source</b> for the custom Apex connector.", body))


    el.append(Spacer(1, 3*mm))


    el += embed_image(IMG2_DS_LIST,


        label="Screenshot  -  GPTfy API Data Source Catalogue",


        label_color=C["green_dark"],


        caption_text="Figure 2.5 - GPTfy API Data Source catalogue - Snowflake API and Test API Data Source (active)")


    el.append(Spacer(1, 3*mm))


    el.append(Paragraph(


        "Click <b>Edit</b> on your chosen data source and fill in the <b>Data Source Details</b> tab:", body))


    el.append(Spacer(1, 2*mm))


    el.append(kv_table([


        ("Data Source Name", "Test API Data Source"),


        ("Named Credential", "SnowflakeDS"),


        ("Source",           "Azure  (GPTfy categorisation field only  -  does not affect Snowflake connectivity)"),


        ("Connector Class",  "SampleDataSourceClass2  (the Apex class deployed in Step 2.4)"),


        ("EndPoint URL",     "Leave blank  -  the endpoint is fully defined in the Named Credential URL"),


    ], accent=C["green_dark"]))


    el.append(Spacer(1, 2*mm))


    el.append(warning("Click Save, then click Activate. The data source must show a green tick in the catalogue before it can be used in a prompt mapping."))


    el.append(Spacer(1, 3*mm))


    el += embed_image(IMG2_EDIT_DS,


        label="Screenshot  -  Edit API Data Source",


        label_color=C["green_dark"],


        caption_text="Figure 2.5b  -  Edit Test API Data Source  -  Named Credential: SnowflakeDS, Connector Class: SampleDataSourceClass2")


    el.append(Spacer(1, 4*mm))





    # 2.6


    el += sh("2.6  GPTfy Setup  -  Prompt with API Data Source Mapping", C["green_dark"])


    el.append(Paragraph(


        "Link the active API Data Source to a prompt via <b>Data Context Mapping</b>. "


        "<b>Navigation:</b> GPTfy  -  ' Prompt Catalog  -  ' [Your Prompt]  -  ' Data Context Mapping  -  ' New", body))


    el.append(Spacer(1, 2*mm))


    el.append(kv_table([


        ("Mapping Name",               "Account Prompt Test ss 1  (or any descriptive name)"),


        ("Target Object",              "Account (Account)"),


        ("Target Object Label",        "Account"),


        ("Select API Data Connection", "Test API Data Source  (active data source from Step 2.5)"),


        ("Select Apex Security Layer", "(optional)"),


    ], accent=C["green_dark"]))


    el.append(Spacer(1, 3*mm))


    el += embed_image(IMG2_MAPPING,


        label="Screenshot  -  Data Context Mapping",


        label_color=C["green_dark"],


        caption_text="Figure 2.6  -  Data Context Mapping linking the prompt to 'Test API Data Source' on the Account object")


    el.append(Spacer(1, 3*mm))


    el.append(sh2("Runtime flow:"))


    el.append(Spacer(1, 1*mm))


    for i, (h, d) in enumerate([


        ("User runs prompt",       "User opens an Account record in Salesforce and triggers the GPTfy prompt."),


        ("GPTfy serialises context","GPTfy serialises the Account record into JSON and calls SampleDataSourceClass2.getExternalData()."),


        ("Apex builds SQL",        "The class extracts the Account Id and builds a Snowflake SQL query filtering by DEPARTMENT.ExternalId."),


        ("Callout fires",          "HTTP POST fires to Snowflake /api/v2/statements via the SnowflakeDS Named Credential."),


        ("Data injected",          "Snowflake returns matching EMPLOYEE + DEPARTMENT rows. GPTfy injects the result into the prompt context for the LLM."),


    ], 1):


        el.append(step(i, h, d, C["green"]))


    el.append(Spacer(1, 4*mm))





    # 2.7 Comparison


    el += sh("2.7  Comparison  -  External Data Source vs GPTfy API Data Source", C["green_dark"])


    el.append(comparison_table(


        ["Aspect", "External Data Source (Sec 1)", "GPTfy API Data Source (Sec 2)"],


        [


            ["SF Connect licence",    "Required",                     "Not required"],


            ["Data access",          "Always-on virtual objects (SOQL)", "On-demand callout at prompt runtime"],


            ["External Objects",     "Yes  -  visible in SF UI",        "No  -  data only in prompt output"],


            ["DML from Salesforce",  " -  Yes (writable ext. objects)", " -  -  No (read-only callout)"],


            ["SQL control",          "Automatic (SF generates)",      "Full control via Apex class"],


            ["Setup complexity",     "Moderate",                      "Low (once Auth Provider/NC exist)"],


            ["Best for",             "Browsing Snowflake data in SF", "AI prompt enrichment with live data"],


        ],


        [40*mm, 62*mm, CW - 102*mm]


    ))


    return el








#  -  - " - " -  Build  -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " -  - " - 


def main():


    doc = SimpleDocTemplate(


        OUTPUT, pagesize=A4,


        leftMargin=LM, rightMargin=RM,


        topMargin=TM + 12*mm, bottomMargin=BM + 9*mm,


        title="Snowflake x Salesforce Integration Guide",


        author="Internal Documentation",


    )


    story  = build_cover()


    story += build_toc()


    story += build_section1()


    story += build_section2()





    doc.build(story,


              onFirstPage=cover_page_cb,


              onLaterPages=header_footer)


    print(f"PDF written: {OUTPUT}")








if __name__ == "__main__":


    main()








