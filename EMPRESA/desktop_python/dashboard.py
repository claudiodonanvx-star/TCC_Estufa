from __future__ import annotations

import tkinter as tk
from tkinter import filedialog
from tkinter import messagebox
from tkinter import ttk

from db import DatabaseClient, DbConfig


CARD_ORDER = [
    "emp_clientes",
    "emp_contratos",
    "emp_leads",
    "emp_usuarios",
    "emp_unidades",
    "emp_sessoes",
    "emp_atividades",
    "emp_contrato_unidades",
]


FONT_UI = "Segoe UI"

THEME_PALETTES: dict[str, dict[str, object]] = {
    "dark": {
        "bg": "#0f1f14",
        "bg_soft": "#1a2f1f",
        "surface": "#1b3323",
        "surface_alt": "#13251a",
        "border": "#3d5c45",
        "text": "#e9f4e8",
        "muted": "#bdd2bf",
        "primary": "#95da72",
        "primary_strong": "#5ea346",
        "primary_dark": "#2f5e35",
        "selection_fg": "#f6fff5",
        "info": "#7bc4ff",
        "warning": "#f5c56e",
        "danger": "#f38181",
        "funnel_colors": ["#5ea346", "#2f5e35", "#416c3f", "#2b7a4b", "#2b5e73", "#7b3f34"],
    },
    "light": {
        "bg": "#eef4ec",
        "bg_soft": "#dce9da",
        "surface": "#ffffff",
        "surface_alt": "#f5faf3",
        "border": "#b7cdb5",
        "text": "#163320",
        "muted": "#4d6b55",
        "primary": "#2f7d32",
        "primary_strong": "#3e9a42",
        "primary_dark": "#296e30",
        "selection_fg": "#f6fff5",
        "info": "#1f6dbe",
        "warning": "#b56e08",
        "danger": "#cc4f4f",
        "funnel_colors": ["#3e9a42", "#296e30", "#4d8952", "#5d8f62", "#2f6e75", "#9e5d31"],
    },
}


COLOR_BG = ""
COLOR_BG_SOFT = ""
COLOR_SURFACE = ""
COLOR_SURFACE_ALT = ""
COLOR_BORDER = ""
COLOR_TEXT = ""
COLOR_MUTED = ""
COLOR_PRIMARY = ""
COLOR_PRIMARY_STRONG = ""
COLOR_PRIMARY_DARK = ""
COLOR_SELECTION_FG = ""
COLOR_INFO = ""
COLOR_WARNING = ""
COLOR_DANGER = ""
FUNNEL_COLORS: list[str] = []


def _set_theme_globals(theme_name: str) -> None:
    palette = THEME_PALETTES[theme_name]

    global COLOR_BG
    global COLOR_BG_SOFT
    global COLOR_SURFACE
    global COLOR_SURFACE_ALT
    global COLOR_BORDER
    global COLOR_TEXT
    global COLOR_MUTED
    global COLOR_PRIMARY
    global COLOR_PRIMARY_STRONG
    global COLOR_PRIMARY_DARK
    global COLOR_SELECTION_FG
    global COLOR_INFO
    global COLOR_WARNING
    global COLOR_DANGER
    global FUNNEL_COLORS

    COLOR_BG = str(palette["bg"])
    COLOR_BG_SOFT = str(palette["bg_soft"])
    COLOR_SURFACE = str(palette["surface"])
    COLOR_SURFACE_ALT = str(palette["surface_alt"])
    COLOR_BORDER = str(palette["border"])
    COLOR_TEXT = str(palette["text"])
    COLOR_MUTED = str(palette["muted"])
    COLOR_PRIMARY = str(palette["primary"])
    COLOR_PRIMARY_STRONG = str(palette["primary_strong"])
    COLOR_PRIMARY_DARK = str(palette["primary_dark"])
    COLOR_SELECTION_FG = str(palette["selection_fg"])
    COLOR_INFO = str(palette["info"])
    COLOR_WARNING = str(palette["warning"])
    COLOR_DANGER = str(palette["danger"])
    FUNNEL_COLORS = list(palette["funnel_colors"])


_set_theme_globals("dark")


class DashboardApp(tk.Tk):
    def __init__(self) -> None:
        super().__init__()
        self.current_theme = "dark"
        _set_theme_globals(self.current_theme)

        self.title("Estufa Smart | Painel Desktop Empresa")
        self.geometry("1366x860")
        self.minsize(1080, 700)
        self.configure(bg=COLOR_BG)

        self.client = DatabaseClient(DbConfig.from_env())
        self.table_counts: dict[str, int] = {}
        self.table_names: list[str] = []
        self.clients_index: dict[int, int] = {}
        self.current_client_id: int | None = None
        self.finance_units_index: dict[int, int] = {}
        self.finance_units_rows: list[dict] = []
        self.current_finance_unit_id: int | None = None
        self.funnel_rows: list[dict] = []

        self._configure_style()
        self._build_layout()
        self._refresh_dashboard()

    def _theme_switch_text(self) -> str:
        return "Modo claro" if self.current_theme == "dark" else "Modo escuro"

    def _toggle_theme(self) -> None:
        self.current_theme = "light" if self.current_theme == "dark" else "dark"
        _set_theme_globals(self.current_theme)
        self.configure(bg=COLOR_BG)

        for child in self.winfo_children():
            child.destroy()

        self._configure_style()
        self._build_layout()
        self._refresh_dashboard()

    def _configure_style(self) -> None:
        style = ttk.Style(self)
        style.theme_use("clam")

        style.configure("Body.TFrame", background=COLOR_BG)
        style.configure("Panel.TFrame", background=COLOR_SURFACE)
        style.configure("Title.TLabel", font=(FONT_UI, 16, "bold"), background=COLOR_SURFACE, foreground=COLOR_TEXT)
        style.configure("Sub.TLabel", font=(FONT_UI, 10), background=COLOR_SURFACE, foreground=COLOR_MUTED)
        style.configure("Head.TLabel", font=(FONT_UI, 13, "bold"), background=COLOR_SURFACE, foreground=COLOR_TEXT)
        style.configure("Value.TLabel", font=(FONT_UI, 11), background=COLOR_SURFACE, foreground=COLOR_TEXT)

        style.configure(
            "Accent.TButton",
            font=(FONT_UI, 10, "bold"),
            foreground=COLOR_SELECTION_FG,
            background=COLOR_PRIMARY_STRONG,
            borderwidth=0,
            padding=(12, 8),
        )
        style.map("Accent.TButton", background=[("active", COLOR_PRIMARY)])

        style.configure("TNotebook", background=COLOR_BG, borderwidth=0)
        style.configure(
            "TNotebook.Tab",
            font=(FONT_UI, 10, "bold"),
            background=COLOR_PRIMARY_DARK,
            foreground=COLOR_TEXT,
            padding=(12, 8),
            borderwidth=0,
        )
        style.map(
            "TNotebook.Tab",
            background=[("selected", COLOR_PRIMARY_STRONG), ("active", COLOR_PRIMARY_DARK)],
            foreground=[("selected", COLOR_SELECTION_FG), ("active", COLOR_TEXT)],
        )

        style.configure(
            "Data.Treeview",
            font=(FONT_UI, 10),
            rowheight=28,
            background=COLOR_SURFACE_ALT,
            fieldbackground=COLOR_SURFACE_ALT,
            foreground=COLOR_TEXT,
            borderwidth=0,
        )
        style.configure(
            "Data.Treeview.Heading",
            font=(FONT_UI, 10, "bold"),
            background=COLOR_PRIMARY_DARK,
            foreground=COLOR_PRIMARY,
            relief="flat",
        )
        style.map(
            "Data.Treeview",
            background=[("selected", COLOR_PRIMARY)],
            foreground=[("selected", COLOR_SELECTION_FG)],
        )

    def _build_layout(self) -> None:
        self._build_header()

        body = ttk.Frame(self, style="Body.TFrame", padding=14)
        body.pack(fill="both", expand=True)

        self.status_label = ttk.Label(body, text="Conectando...", style="Sub.TLabel")
        self.status_label.pack(fill="x", pady=(0, 10))

        self.notebook = ttk.Notebook(body)
        self.notebook.pack(fill="both", expand=True)

        self.tab_overview = ttk.Frame(self.notebook, style="Panel.TFrame", padding=10)
        self.tab_funnel = ttk.Frame(self.notebook, style="Panel.TFrame", padding=10)
        self.tab_alerts = ttk.Frame(self.notebook, style="Panel.TFrame", padding=10)
        self.tab_clients = ttk.Frame(self.notebook, style="Panel.TFrame", padding=10)
        self.tab_finance = ttk.Frame(self.notebook, style="Panel.TFrame", padding=10)

        self.notebook.add(self.tab_overview, text="Visao Geral")
        self.notebook.add(self.tab_funnel, text="Funil de Leads")
        self.notebook.add(self.tab_alerts, text="Alertas")
        self.notebook.add(self.tab_clients, text="Cliente 360")
        self.notebook.add(self.tab_finance, text="Financeiro")

        self._build_overview_tab()
        self._build_funnel_tab()
        self._build_alerts_tab()
        self._build_clients_tab()
        self._build_finance_tab()

    def _build_header(self) -> None:
        header = tk.Frame(
            self,
            bg=COLOR_BG_SOFT,
            padx=16,
            pady=12,
            highlightthickness=1,
            highlightbackground=COLOR_BORDER,
        )
        header.pack(fill="x")

        left = tk.Frame(header, bg=COLOR_BG_SOFT)
        left.pack(side="left", fill="x", expand=True)

        tk.Label(
            left,
            text="Estufa Smart • Gestao Empresarial",
            bg=COLOR_BG_SOFT,
            fg=COLOR_PRIMARY,
            font=(FONT_UI, 18, "bold"),
        ).pack(anchor="w")
        tk.Label(
            left,
            text="Painel desktop integrado ao visual do Web e Mobile",
            bg=COLOR_BG_SOFT,
            fg=COLOR_MUTED,
            font=(FONT_UI, 11),
        ).pack(anchor="w")

        actions = tk.Frame(header, bg=COLOR_BG_SOFT)
        actions.pack(side="right", pady=4)

        ttk.Button(actions, text=self._theme_switch_text(), style="Accent.TButton", command=self._toggle_theme).pack(
            side="right", padx=(8, 0)
        )
        ttk.Button(actions, text="Atualizar agora", style="Accent.TButton", command=self._refresh_dashboard).pack(side="right")

    def _build_overview_tab(self) -> None:
        cards_wrapper = tk.Frame(self.tab_overview, bg=COLOR_BG)
        cards_wrapper.pack(fill="x", pady=(0, 8))

        self.card_values: dict[str, tk.Label] = {}
        for index, table_name in enumerate(CARD_ORDER):
            card = tk.Frame(
                cards_wrapper,
                bg=COLOR_SURFACE,
                bd=1,
                relief="solid",
                highlightthickness=1,
                highlightbackground=COLOR_BORDER,
                padx=12,
                pady=10,
            )
            card.grid(row=index // 4, column=index % 4, padx=6, pady=6, sticky="nsew")
            cards_wrapper.columnconfigure(index % 4, weight=1)

            tk.Label(card, text=table_name, bg=COLOR_SURFACE, fg=COLOR_MUTED, font=(FONT_UI, 10, "bold")).pack(anchor="w")
            value_label = tk.Label(card, text="-", bg=COLOR_SURFACE, fg=COLOR_PRIMARY, font=(FONT_UI, 22, "bold"))
            value_label.pack(anchor="w", pady=(4, 0))
            self.card_values[table_name] = value_label

        split = ttk.Panedwindow(self.tab_overview, orient="horizontal")
        split.pack(fill="both", expand=True, pady=(8, 0))

        left = ttk.Frame(split, style="Panel.TFrame", padding=(0, 0, 8, 0))
        right = ttk.Frame(split, style="Panel.TFrame")
        split.add(left, weight=1)
        split.add(right, weight=4)

        ttk.Label(left, text="Tabelas emp_", style="Head.TLabel").pack(anchor="w", pady=(0, 8))
        self.tables_listbox = tk.Listbox(
            left,
            exportselection=False,
            activestyle="none",
            bg=COLOR_SURFACE_ALT,
            fg=COLOR_TEXT,
            font=(FONT_UI, 11),
            selectbackground=COLOR_PRIMARY,
            selectforeground=COLOR_SELECTION_FG,
            bd=1,
            relief="solid",
            highlightthickness=1,
            highlightbackground=COLOR_BORDER,
        )
        self.tables_listbox.pack(fill="both", expand=True)
        self.tables_listbox.bind("<<ListboxSelect>>", self._on_table_selected)

        ttk.Label(right, text="Registros", style="Head.TLabel").pack(anchor="w", pady=(0, 8))
        self.main_tree = self._create_tree_with_scrollbars(right)

    def _build_funnel_tab(self) -> None:
        ttk.Label(self.tab_funnel, text="Distribuicao de leads por status", style="Head.TLabel").pack(anchor="w", pady=(0, 10))

        content = ttk.Frame(self.tab_funnel, style="Panel.TFrame")
        content.pack(fill="both", expand=True)
        content.columnconfigure(0, weight=2)
        content.columnconfigure(1, weight=1)
        content.rowconfigure(0, weight=1)

        canvas_card = tk.Frame(content, bg=COLOR_SURFACE, bd=1, relief="solid", highlightbackground=COLOR_BORDER, highlightthickness=1)
        canvas_card.grid(row=0, column=0, sticky="nsew", padx=(0, 8))

        self.funnel_canvas = tk.Canvas(canvas_card, bg=COLOR_SURFACE_ALT, highlightthickness=0)
        self.funnel_canvas.pack(fill="both", expand=True)
        self.funnel_canvas.bind("<Configure>", self._on_funnel_resize)

        table_card = ttk.Frame(content, style="Panel.TFrame")
        table_card.grid(row=0, column=1, sticky="nsew")

        ttk.Label(table_card, text="Resumo por status", style="Head.TLabel").pack(anchor="w", pady=(0, 8))
        self.funnel_tree = self._create_tree_with_scrollbars(table_card, height=14)

    def _build_alerts_tab(self) -> None:
        top = ttk.Frame(self.tab_alerts, style="Panel.TFrame")
        top.pack(fill="x", pady=(0, 10))
        ttk.Label(top, text="Alertas operacionais", style="Head.TLabel").pack(side="left")
        ttk.Label(top, text="Contratos (30 dias) e atividades pendentes (7 dias)", style="Sub.TLabel").pack(side="left", padx=12)

        panes = ttk.Panedwindow(self.tab_alerts, orient="vertical")
        panes.pack(fill="both", expand=True)

        up = ttk.Frame(panes, style="Panel.TFrame")
        down = ttk.Frame(panes, style="Panel.TFrame")
        panes.add(up, weight=1)
        panes.add(down, weight=1)

        ttk.Label(up, text="Contratos proximos do vencimento", style="Head.TLabel").pack(anchor="w", pady=(0, 6))
        self.contract_alert_tree = self._create_tree_with_scrollbars(up)

        ttk.Label(down, text="Atividades pendentes com prazo curto", style="Head.TLabel").pack(anchor="w", pady=(0, 6))
        self.activity_alert_tree = self._create_tree_with_scrollbars(down)

    def _build_clients_tab(self) -> None:
        top = ttk.Frame(self.tab_clients, style="Panel.TFrame")
        top.pack(fill="x", pady=(0, 10))
        ttk.Label(top, text="Visao 360 do cliente", style="Head.TLabel").pack(side="left")
        ttk.Button(top, text="Historico de boletos pagos", style="Accent.TButton", command=self._open_current_client_paid_boletos).pack(
            side="right"
        )

        split = ttk.Panedwindow(self.tab_clients, orient="horizontal")
        split.pack(fill="both", expand=True)

        left = ttk.Frame(split, style="Panel.TFrame", padding=(0, 0, 8, 0))
        right = ttk.Frame(split, style="Panel.TFrame")
        split.add(left, weight=1)
        split.add(right, weight=3)

        ttk.Label(left, text="Clientes", style="Head.TLabel").pack(anchor="w", pady=(0, 8))
        self.clients_listbox = tk.Listbox(
            left,
            exportselection=False,
            activestyle="none",
            bg=COLOR_SURFACE_ALT,
            fg=COLOR_TEXT,
            font=(FONT_UI, 11),
            selectbackground=COLOR_PRIMARY,
            selectforeground=COLOR_SELECTION_FG,
            bd=1,
            relief="solid",
            highlightthickness=1,
            highlightbackground=COLOR_BORDER,
        )
        self.clients_listbox.pack(fill="both", expand=True)
        self.clients_listbox.bind("<<ListboxSelect>>", self._on_client_selected)
        self.clients_listbox.bind("<Double-Button-1>", self._on_client_double_click)

        summary = tk.Frame(
            right,
            bg=COLOR_SURFACE,
            bd=1,
            relief="solid",
            highlightbackground=COLOR_BORDER,
            highlightthickness=1,
            padx=12,
            pady=10,
        )
        summary.pack(fill="x", pady=(0, 10))

        self.client_name = tk.Label(
            summary,
            text="Selecione um cliente",
            bg=COLOR_SURFACE,
            fg=COLOR_TEXT,
            font=(FONT_UI, 14, "bold"),
        )
        self.client_name.pack(anchor="w")

        summary_grid = tk.Frame(summary, bg=COLOR_SURFACE)
        summary_grid.pack(fill="x", pady=(8, 0))
        self.client_metrics: dict[str, tk.Label] = {}
        for idx, metric in enumerate(["Contratos", "Unidades", "Atividades pendentes", "Receita ativa", "Adimplencia"]):
            card = tk.Frame(
                summary_grid,
                bg=COLOR_SURFACE_ALT,
                bd=1,
                relief="solid",
                highlightbackground=COLOR_BORDER,
                highlightthickness=1,
            )
            card.grid(row=0, column=idx, sticky="nsew", padx=5)
            summary_grid.columnconfigure(idx, weight=1)
            tk.Label(card, text=metric, bg=COLOR_SURFACE_ALT, fg=COLOR_MUTED, font=(FONT_UI, 10, "bold")).pack(
                anchor="w", padx=8, pady=(8, 2)
            )
            value = tk.Label(card, text="-", bg=COLOR_SURFACE_ALT, fg=COLOR_PRIMARY, font=(FONT_UI, 14, "bold"))
            value.pack(anchor="w", padx=8, pady=(0, 8))
            self.client_metrics[metric] = value

        lower_notebook = ttk.Notebook(right)
        lower_notebook.pack(fill="both", expand=True)

        contracts_tab = ttk.Frame(lower_notebook, style="Panel.TFrame", padding=6)
        units_tab = ttk.Frame(lower_notebook, style="Panel.TFrame", padding=6)
        activities_tab = ttk.Frame(lower_notebook, style="Panel.TFrame", padding=6)

        lower_notebook.add(contracts_tab, text="Contratos")
        lower_notebook.add(units_tab, text="Unidades")
        lower_notebook.add(activities_tab, text="Atividades")

        self.client_contracts_tree = self._create_tree_with_scrollbars(contracts_tab)
        self.client_units_tree = self._create_tree_with_scrollbars(units_tab)
        self.client_activities_tree = self._create_tree_with_scrollbars(activities_tab)

    def _build_finance_tab(self) -> None:
        top = ttk.Frame(self.tab_finance, style="Panel.TFrame")
        top.pack(fill="x", pady=(0, 10))

        ttk.Label(top, text="Financeiro por boleto", style="Head.TLabel").pack(side="left")
        ttk.Label(
            top,
            text="Regra: ate 5 dias apos vencimento. Se ultrapassar sem pagamento, unidade fica BFP.",
            style="Sub.TLabel",
        ).pack(side="left", padx=10)
        ttk.Button(top, text="Regerar simulacao", style="Accent.TButton", command=self._rebuild_finance_simulation).pack(
            side="right"
        )

        summary_frame = tk.Frame(self.tab_finance, bg=COLOR_BG)
        summary_frame.pack(fill="x", pady=(0, 10))

        self.finance_summary_labels: dict[str, tk.Label] = {}
        for idx, status in enumerate(["ATIVO", "BFP", "CANCELADO", "TOTAL_BOLETOS"]):
            color = COLOR_PRIMARY
            if status == "BFP":
                color = COLOR_DANGER
            elif status == "CANCELADO":
                color = COLOR_MUTED

            card = tk.Frame(
                summary_frame,
                bg=COLOR_SURFACE,
                bd=1,
                relief="solid",
                highlightthickness=1,
                highlightbackground=COLOR_BORDER,
                padx=12,
                pady=10,
            )
            card.grid(row=0, column=idx, padx=6, pady=6, sticky="nsew")
            summary_frame.columnconfigure(idx, weight=1)

            title = "Total boletos" if status == "TOTAL_BOLETOS" else f"Unidades {status}"
            tk.Label(card, text=title, bg=COLOR_SURFACE, fg=COLOR_MUTED, font=(FONT_UI, 10, "bold")).pack(anchor="w")
            value_label = tk.Label(card, text="0", bg=COLOR_SURFACE, fg=color, font=(FONT_UI, 20, "bold"))
            value_label.pack(anchor="w", pady=(4, 0))
            self.finance_summary_labels[status] = value_label

        split = ttk.Panedwindow(self.tab_finance, orient="horizontal")
        split.pack(fill="both", expand=True)

        left = ttk.Frame(split, style="Panel.TFrame", padding=(0, 0, 8, 0))
        right = ttk.Frame(split, style="Panel.TFrame")
        split.add(left, weight=1)
        split.add(right, weight=3)

        ttk.Label(left, text="Unidades e status", style="Head.TLabel").pack(anchor="w", pady=(0, 8))
        self.finance_units_listbox = tk.Listbox(
            left,
            exportselection=False,
            activestyle="none",
            bg=COLOR_SURFACE_ALT,
            fg=COLOR_TEXT,
            font=(FONT_UI, 11),
            selectbackground=COLOR_PRIMARY,
            selectforeground=COLOR_SELECTION_FG,
            bd=1,
            relief="solid",
            highlightthickness=1,
            highlightbackground=COLOR_BORDER,
        )
        self.finance_units_listbox.pack(fill="both", expand=True)
        self.finance_units_listbox.bind("<<ListboxSelect>>", self._on_finance_unit_selected)

        actions = ttk.Frame(right, style="Panel.TFrame")
        actions.pack(fill="x", pady=(0, 8))
        ttk.Label(actions, text="Historico de boletos", style="Head.TLabel").pack(side="left")
        ttk.Button(actions, text="Baixar PDF selecionado", style="Accent.TButton", command=self._download_selected_boleto).pack(
            side="right", padx=(8, 0)
        )
        ttk.Button(actions, text="Confirmar pagamento", style="Accent.TButton", command=self._confirm_selected_boleto_payment).pack(
            side="right"
        )

        self.finance_boletos_tree = self._create_tree_with_scrollbars(right)

    def _create_tree_with_scrollbars(self, parent: ttk.Frame, height: int = 18) -> ttk.Treeview:
        frame = ttk.Frame(parent, style="Panel.TFrame")
        frame.pack(fill="both", expand=True)

        tree = ttk.Treeview(frame, show="headings", style="Data.Treeview", height=height)
        tree.grid(row=0, column=0, sticky="nsew")

        yscroll = ttk.Scrollbar(frame, orient="vertical", command=tree.yview)
        xscroll = ttk.Scrollbar(frame, orient="horizontal", command=tree.xview)
        tree.configure(yscrollcommand=yscroll.set, xscrollcommand=xscroll.set)

        yscroll.grid(row=0, column=1, sticky="ns")
        xscroll.grid(row=1, column=0, sticky="ew")
        frame.rowconfigure(0, weight=1)
        frame.columnconfigure(0, weight=1)
        return tree

    def _refresh_dashboard(self) -> None:
        try:
            self.client.ping()
            self.client.bootstrap_finance_data()
            self.table_names = self.client.list_emp_tables()
            self.table_counts = {name: self.client.count_rows(name) for name in self.table_names}

            self._refresh_cards()
            self._refresh_table_browser()
            self._refresh_funnel()
            self._refresh_alerts()
            self._refresh_clients()
            self._refresh_finance()

            self.status_label.config(text="Conectado e atualizado com sucesso.")
        except Exception as ex:
            self.status_label.config(text="Falha ao atualizar dashboard.")
            messagebox.showerror("Erro", str(ex))

    def _refresh_cards(self) -> None:
        for table_name, label in self.card_values.items():
            label.config(text=str(self.table_counts.get(table_name, 0)))

    def _refresh_table_browser(self) -> None:
        self.tables_listbox.delete(0, tk.END)
        for table_name in self.table_names:
            count = self.table_counts.get(table_name, 0)
            self.tables_listbox.insert(tk.END, f"{table_name} ({count})")

        if self.table_names:
            self.tables_listbox.selection_clear(0, tk.END)
            self.tables_listbox.selection_set(0)
            self._show_table_data(self.table_names[0])
        else:
            self._clear_tree(self.main_tree)

    def _refresh_funnel(self) -> None:
        self.funnel_rows = self.client.get_leads_funnel()
        self._render_tree(self.funnel_tree, self.funnel_rows)
        self._draw_funnel_chart(self.funnel_rows)

    def _refresh_alerts(self) -> None:
        contracts = self.client.get_contract_alerts(days=30)
        activities = self.client.get_activity_alerts(days=7)
        self._render_tree(self.contract_alert_tree, contracts)
        self._render_tree(self.activity_alert_tree, activities)

    def _refresh_clients(self) -> None:
        clients = self.client.list_clients()
        self.clients_index.clear()
        self.clients_listbox.delete(0, tk.END)

        for idx, client in enumerate(clients):
            label = f"{client['nome_fantasia']} - {client['cidade']}/{client['estado']}"
            self.clients_listbox.insert(tk.END, label)
            self.clients_index[idx] = int(client["id"])

        if clients:
            self.clients_listbox.selection_clear(0, tk.END)
            self.clients_listbox.selection_set(0)
            self._show_client_data(int(clients[0]["id"]))
        else:
            self.current_client_id = None
            self.client_name.config(text="Nenhum cliente encontrado")

    def _on_table_selected(self, _event: tk.Event) -> None:
        selection = self.tables_listbox.curselection()
        if not selection:
            return
        index = int(selection[0])
        if index >= len(self.table_names):
            return
        self._show_table_data(self.table_names[index])

    def _show_table_data(self, table_name: str) -> None:
        rows = self.client.fetch_rows(table_name, limit=150)
        self._render_tree(self.main_tree, rows)
        self.status_label.config(text=f"Tabela selecionada: {table_name} | Total: {self.table_counts.get(table_name, 0)}")

    def _on_client_selected(self, _event: tk.Event) -> None:
        selection = self.clients_listbox.curselection()
        if not selection:
            return
        client_id = self.clients_index.get(int(selection[0]))
        if client_id is None:
            return
        self._show_client_data(client_id)

    def _show_client_data(self, client_id: int) -> None:
        self.current_client_id = client_id
        summary = self.client.get_client_overview(client_id)
        adimplencia = self.client.get_client_adimplencia(client_id)
        contracts = self.client.get_client_contracts(client_id)
        units = self.client.get_client_units(client_id)
        activities = self.client.get_client_activities(client_id, limit=100)

        self.client_name.config(text=str(summary.get("cliente", "Cliente")))
        self.client_metrics["Contratos"].config(text=str(summary.get("contratos", 0)))
        self.client_metrics["Unidades"].config(text=str(summary.get("unidades", 0)))
        self.client_metrics["Atividades pendentes"].config(text=str(summary.get("atividades_pendentes", 0)))
        receita = float(summary.get("receita_ativa", 0) or 0)
        self.client_metrics["Receita ativa"].config(text=f"R$ {receita:,.2f}".replace(",", "X").replace(".", ",").replace("X", "."))

        percentual = float(adimplencia.get("adimplencia_percentual", 0) or 0)
        avaliados = int(adimplencia.get("boletos_avaliados", 0) or 0)
        if avaliados == 0:
            self.client_metrics["Adimplencia"].config(text="Sem base", fg=COLOR_MUTED)
        else:
            color = COLOR_DANGER
            if percentual >= 90:
                color = COLOR_PRIMARY
            elif percentual >= 70:
                color = COLOR_WARNING
            percent_text = f"{percentual:.1f}".replace(".", ",")
            self.client_metrics["Adimplencia"].config(text=f"{percent_text}% ({avaliados})", fg=color)

        self._render_tree(self.client_contracts_tree, contracts)
        self._render_tree(self.client_units_tree, units)
        self._render_tree(self.client_activities_tree, activities)

    def _on_client_double_click(self, _event: tk.Event) -> None:
        selection = self.clients_listbox.curselection()
        if not selection:
            return
        client_id = self.clients_index.get(int(selection[0]))
        if client_id is None:
            return
        self._open_client_paid_boletos_window(client_id)

    def _open_current_client_paid_boletos(self) -> None:
        if self.current_client_id is None:
            messagebox.showwarning("Cliente", "Selecione um cliente para ver os boletos pagos.")
            return
        self._open_client_paid_boletos_window(self.current_client_id)

    def _open_client_paid_boletos_window(self, client_id: int) -> None:
        summary = self.client.get_client_paid_boletos_summary(client_id)
        rows = self.client.get_client_paid_boletos(client_id, limit=5000)

        win = tk.Toplevel(self)
        win.title("Historico completo de boletos pagos")
        win.geometry("1200x720")
        win.minsize(920, 580)
        win.configure(bg=COLOR_BG)

        wrapper = ttk.Frame(win, style="Body.TFrame", padding=12)
        wrapper.pack(fill="both", expand=True)

        title = str(summary.get("cliente") or "Cliente")
        ttk.Label(wrapper, text=f"Boletos pagos - {title}", style="Head.TLabel").pack(anchor="w")
        ttk.Label(
            wrapper,
            text="Historico completo de pagamentos, independente de estar perto do vencimento.",
            style="Sub.TLabel",
        ).pack(anchor="w", pady=(0, 10))

        cards = tk.Frame(wrapper, bg=COLOR_BG)
        cards.pack(fill="x", pady=(0, 10))

        total_pagos = int(summary.get("total_pagos", 0) or 0)
        pagos_regulares = int(summary.get("pagos_regulares", 0) or 0)
        pagos_apos = int(summary.get("pagos_apos_5_dias", 0) or 0)
        media_atraso = summary.get("media_atraso_dias")

        card_data = [
            ("Total pagos", str(total_pagos), COLOR_PRIMARY),
            ("Pagos no prazo (5 dias)", str(pagos_regulares), COLOR_INFO),
            ("Pagos apos 5 dias", str(pagos_apos), COLOR_WARNING),
            ("Media atraso (dias)", str(media_atraso if media_atraso is not None else 0), COLOR_DANGER),
        ]

        for idx, (label, value, color) in enumerate(card_data):
            card = tk.Frame(
                cards,
                bg=COLOR_SURFACE,
                bd=1,
                relief="solid",
                highlightbackground=COLOR_BORDER,
                highlightthickness=1,
                padx=12,
                pady=10,
            )
            card.grid(row=0, column=idx, padx=6, pady=6, sticky="nsew")
            cards.columnconfigure(idx, weight=1)
            tk.Label(card, text=label, bg=COLOR_SURFACE, fg=COLOR_MUTED, font=(FONT_UI, 10, "bold")).pack(anchor="w")
            tk.Label(card, text=value, bg=COLOR_SURFACE, fg=color, font=(FONT_UI, 20, "bold")).pack(anchor="w", pady=(4, 0))

        tree = self._create_tree_with_scrollbars(wrapper, height=18)
        self._render_tree(tree, rows)

    def _refresh_finance(self, preferred_unit_id: int | None = None) -> None:
        summary_rows = self.client.get_finance_status_summary()
        summary_map = {str(row.get("status")): int(row.get("total", 0) or 0) for row in summary_rows}

        self.finance_summary_labels["ATIVO"].config(text=str(summary_map.get("ATIVO", 0)))
        self.finance_summary_labels["BFP"].config(text=str(summary_map.get("BFP", 0)))
        self.finance_summary_labels["CANCELADO"].config(text=str(summary_map.get("CANCELADO", 0)))

        self.finance_units_rows = self.client.list_finance_units()
        total_boletos = sum(int(row.get("total_boletos", 0) or 0) for row in self.finance_units_rows)
        self.finance_summary_labels["TOTAL_BOLETOS"].config(text=str(total_boletos))

        self.finance_units_index.clear()
        self.finance_units_listbox.delete(0, tk.END)
        for idx, row in enumerate(self.finance_units_rows):
            unit_id = int(row.get("id"))
            status = str(row.get("status_financeiro", "ATIVO"))
            name = str(row.get("nome_unidade", f"Unidade {unit_id}"))
            pending = int(row.get("boletos_pendentes", 0) or 0)
            bfp = int(row.get("boletos_bfp", 0) or 0)
            label = f"[{status}] {name} | pendentes: {pending} | bfp: {bfp}"
            self.finance_units_listbox.insert(tk.END, label)
            self.finance_units_index[idx] = unit_id

        if self.finance_units_rows:
            target_id = preferred_unit_id if preferred_unit_id is not None else self.current_finance_unit_id
            selected_index = 0
            if target_id is not None:
                for idx, row in enumerate(self.finance_units_rows):
                    if int(row.get("id")) == int(target_id):
                        selected_index = idx
                        break

            self.finance_units_listbox.selection_clear(0, tk.END)
            self.finance_units_listbox.selection_set(selected_index)
            selected_id = int(self.finance_units_rows[selected_index]["id"])
            self._show_finance_boletos(selected_id)
        else:
            self.current_finance_unit_id = None
            self._clear_tree(self.finance_boletos_tree)

    def _on_finance_unit_selected(self, _event: tk.Event) -> None:
        selection = self.finance_units_listbox.curselection()
        if not selection:
            return
        unit_id = self.finance_units_index.get(int(selection[0]))
        if unit_id is None:
            return
        self._show_finance_boletos(unit_id)

    def _show_finance_boletos(self, unit_id: int) -> None:
        self.current_finance_unit_id = unit_id
        boletos = self.client.get_unit_boletos(unit_id, limit=240)
        self._render_tree(self.finance_boletos_tree, boletos)

    def _rebuild_finance_simulation(self) -> None:
        try:
            self.client.bootstrap_finance_data(reset_existing=True)
            self._refresh_finance(preferred_unit_id=self.current_finance_unit_id)
            self.status_label.config(text="Boletos simulados recriados com sucesso.")
        except Exception as ex:
            messagebox.showerror("Erro financeiro", str(ex))

    def _download_selected_boleto(self) -> None:
        boleto_id = self._get_selected_boleto_id()
        if boleto_id is None:
            messagebox.showwarning("Boleto", "Selecione um boleto na grade para baixar o PDF.")
            return

        boleto_data = self.client.get_boleto_pdf(boleto_id)
        if boleto_data is None:
            messagebox.showwarning("Boleto", "Este boleto nao possui PDF armazenado.")
            return

        file_name, payload = boleto_data
        save_path = filedialog.asksaveasfilename(
            title="Salvar boleto PDF",
            defaultextension=".pdf",
            initialfile=file_name,
            filetypes=[("PDF", "*.pdf"), ("Todos os arquivos", "*.*")],
        )
        if not save_path:
            return

        with open(save_path, "wb") as output_file:
            output_file.write(payload)

        self.status_label.config(text=f"Boleto {boleto_id} salvo em {save_path}")
        messagebox.showinfo("Boleto", "PDF salvo com sucesso.")

    def _confirm_selected_boleto_payment(self) -> None:
        boleto_id = self._get_selected_boleto_id()
        if boleto_id is None:
            messagebox.showwarning("Pagamento", "Selecione um boleto na grade para confirmar o pagamento.")
            return

        self.client.mark_boleto_paid(boleto_id)
        self._refresh_finance(preferred_unit_id=self.current_finance_unit_id)
        self.status_label.config(text=f"Pagamento confirmado para o boleto {boleto_id}.")
        messagebox.showinfo("Pagamento", "Pagamento confirmado com sucesso.")

    def _get_selected_boleto_id(self) -> int | None:
        selected_items = self.finance_boletos_tree.selection()
        if not selected_items:
            return None

        item = self.finance_boletos_tree.item(selected_items[0])
        values = item.get("values") or []
        columns = list(self.finance_boletos_tree["columns"])
        if not columns or not values:
            return None

        try:
            id_index = columns.index("boleto_id")
        except ValueError:
            return None

        if id_index >= len(values):
            return None

        try:
            return int(values[id_index])
        except (TypeError, ValueError):
            return None

    def _render_tree(self, tree: ttk.Treeview, rows: list[dict]) -> None:
        self._clear_tree(tree)
        if not rows:
            return

        columns = list(rows[0].keys())
        tree["columns"] = columns
        for column in columns:
            tree.heading(column, text=column)
            tree.column(column, width=140, minwidth=90, anchor="w")

        for row in rows:
            values = [self._format_value(row.get(column)) for column in columns]
            tree.insert("", "end", values=values)

    def _clear_tree(self, tree: ttk.Treeview) -> None:
        tree.delete(*tree.get_children())
        tree["columns"] = ()

    def _on_funnel_resize(self, _event: tk.Event) -> None:
        self._draw_funnel_chart(self.funnel_rows)

    def _draw_funnel_chart(self, rows: list[dict]) -> None:
        self.funnel_canvas.delete("all")
        if not rows:
            self.funnel_canvas.create_text(120, 60, text="Sem dados de leads", fill=COLOR_MUTED, font=(FONT_UI, 12, "bold"))
            return

        width = max(self.funnel_canvas.winfo_width(), 300)
        bar_height = 36
        spacing = 16
        left = 24
        top = 24
        max_value = max(int(r.get("total", 0) or 0) for r in rows)
        colors = FUNNEL_COLORS

        for idx, row in enumerate(rows):
            total = int(row.get("total", 0) or 0)
            status = str(row.get("status", "SEM_STATUS"))
            usable = width - 260
            bar_w = int((total / max_value) * usable) if max_value > 0 else 0
            y0 = top + idx * (bar_height + spacing)
            y1 = y0 + bar_height

            self.funnel_canvas.create_rectangle(left, y0, left + bar_w, y1, fill=colors[idx % len(colors)], width=0)
            self.funnel_canvas.create_text(
                left + 6,
                (y0 + y1) / 2,
                text=status,
                fill=COLOR_TEXT,
                anchor="w",
                font=(FONT_UI, 10, "bold"),
            )
            self.funnel_canvas.create_text(
                left + bar_w + 12,
                (y0 + y1) / 2,
                text=str(total),
                fill=COLOR_TEXT,
                anchor="w",
                font=(FONT_UI, 11, "bold"),
            )

    @staticmethod
    def _format_value(value: object) -> str:
        if value is None:
            return ""
        if isinstance(value, bytes):
            return "1" if value != b"\x00" else "0"
        return str(value)
