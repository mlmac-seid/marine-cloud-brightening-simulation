library(tidyverse)

format_engr = function(x, digits = 6) {
  x_sci <- formatC(x, digits = digits, format = "e", flag = "#",
                   drop0trailing = FALSE)
  parts <- str_match(x_sci,
                     str_c("^",
                           "(<sign>[+-])?",
                           "(?<int>[0-9]+)",
                           "(?<decimal>\\.(?<frac>[0-9]+)?)?",
                           "([Ee](?<exp>(?<expsign>[+-])?(?<expval>[0-9]+)))?"
                     )) %>%
    set_names(c("x_sci", "sign", "int", "decimal", "frac",
                "exp_str", "exp", "exp_sign", "exp_val"))

  if (! is.na(parts['exp'])) {
    exp <- as.integer(parts['exp'])

    exp_adj <- exp %% 3
    if (exp_adj > 0) {
      if (is.na(parts['frac'])) {
        parts['frac'] <- ""
      }
      if (str_length(parts['frac']) < exp_adj) {
        parts['frac'] <- str_c(parts['frac'],
                               strrep("0", exp_adj - str_length(parts['frac'])))
      }
      delta <- str_sub(parts['frac'], end = exp_adj)
      parts['frac'] <- str_sub(parts['frac'], exp_adj + 1)
      parts['int'] <- str_c(parts['int'], delta)
      parts['exp'] <- as.character( as.integer(parts['exp']) - exp_adj )
      parts <- parts %>% map_chr(~ifelse(is.na(.x), "", .x))
      x_sci <- str_c(parts['sign'], parts['int'], ".", parts['frac'],
                     "e", parts['exp'])
    }
  }
  x_sci
}

format_md = function(x, digits = NULL,
                     format = c('normal', 'auto', 'scientific',
                                'engineering'),
                     comma = FALSE,
                     output_format = c("markdown", "latex")) {
  x = unname(x)
  format = match.arg(format)
  output_format = match.arg(output_format)
  mark = ifelse(comma, ',', '')

  fixup_scientific = function(s, output_format = c("markdown", "latex")) {
    output_format = match.arg(output_format)
    if (output_format == 'markdown') {
      str_replace_all(s,  c('\\+' = '',
                            '[Ee](-?)0*(0|[1-9][0-9]*)$' = '&times;10^\\1\\2^'))
    } else {
      str_replace_all(s,  c('\\+' = '',
                            '[Ee](-?)0*(0|[1-9][0-9]*)$' = '\\times 10^{\\1\\2}')) %>%
        str_c("\\(", ., "\\)")
    }
  }

  if (! is.null(digits)) x = signif(x, digits + 1)
  if (format == 'auto') {
    if (! is.null(digits)) digits = digits + 1
    fixed = formatC(x, digits = digits, format = 'fg', flag = '#',
                    big.mark = mark)
    sci = formatC(x, digits = digits, format = 'e')
    formatted = ifelse(str_length(fixed) > getOption('scipen') + str_length(sci),
                       fixup_scientific(sci, output_format = output_format),
                       fixed)
  } else if (format == "normal") {
    if (! is.null(digits)) digits = digits + 1
    formatted = formatC(x, digits = digits, format = 'fg', flag = '#',
                        big.mark = mark)
  } else if (format == "scientific") {
    formatted = formatC(x, digits = digits, format = 'e') %>%
      fixup_scientific(output_format = output_format)
  } else if (format == "engineering") {
    formatted = format_engr(x, digits = digits) %>%
      fixup_scientific(output_format = output_format)
  }
  formatted
}
