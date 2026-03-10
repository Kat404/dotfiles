" --- Esenciales de Comportamiento ---
set nocompatible              " Desactiva la compatibilidad con el viejo Vi
syntax on                     " Resaltado de sintaxis
filetype plugin indent on     " Detecta tipo de archivo y carga plugins/identación
set encoding=utf-8            " Siempre UTF-8
set hidden                    " Permite cambiar de buffer sin guardar cambios

" --- UI & UX ---
set number relativenumber     " Números híbridos (ideal para saltos de línea con 'j'/'k')
set mouse=a                   " Soporte para mouse (útil en terminales modernas como Kitty)
set termguicolors             " Colores reales
set cursorline                " Resalta la línea actual
set showmode                  " Muestra si estás en INSERT, VISUAL, etc.

" --- Búsqueda y Navegación ---
set ignorecase                " Ignora mayúsculas en búsquedas...
set smartcase                 " ...a menos que uses una mayúscula explícitamente
set incsearch                 " Búsqueda incremental
set hlsearch                  " Resalta coincidencias de búsqueda

" --- Edición y Tabulación ---
set expandtab                 " Convierte tabs en espacios (estándar FOSS moderno)
set shiftwidth=4              " Ancho de la identación
set softtabstop=4
set autoindent                " Copia la identación de la línea anterior

" --- Utilidades Integradas ---
set wildmenu                  " Menú visual para autocompletado de comandos
set path+=**                  " Permite buscar archivos recursivamente con :find
set clipboard=unnamedplus     " Usa el portapapeles del sistema (requiere xclip o wl-copy)
