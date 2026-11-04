+++
title = "How to write a note"
date = 2026-11-04
draft = true
tags = ["meta"]
summary = "Everything this setup can do, in one page. Delete when you no longer need it."
+++

This page exists to show you the syntax. Copy it, or delete it once the
syntax is in your fingers.

## Math

Write inline math between single dollars: $f(x) = \sum_{i=1}^{n} w_i x_i$,
and it sits in the sentence at the right size.

Display math goes between double dollars on its own line:

$$
\mathcal{L}(\theta) = -\frac{1}{N}\sum_{i=1}^{N} \log p_\theta(y_i \mid x_i)
$$

Both are rendered when the site is built, so nothing loads in the browser and
nothing flashes before it appears.

## Collapsible detail

Use this when a derivation or a caveat would interrupt the flow.

{{< fold "Why the gradient has that form" >}}
Differentiating the loss with respect to $\theta$ and using the chain rule,

$$
\nabla_\theta \mathcal{L} = -\frac{1}{N}\sum_{i=1}^{N} \nabla_\theta \log p_\theta(y_i \mid x_i).
$$

Markdown works in here: **bold**, `code`, lists, links, more math.
{{< /fold >}}

Add a second argument to have one start expanded:

{{< fold "Already open" "open" >}}
This one is expanded when the page loads.
{{< /fold >}}

## The usual Markdown

**Bold**, *italic*, `inline code`, [links](https://gylia.github.io/).

- Bullet lists
- Work as expected

1. So do
2. Numbered ones

> Block quotes for things worth setting apart.

```python
def loss(theta, x, y):
    return -log_prob(theta, x, y).mean()
```

| Column | Value |
| --- | --- |
| Tables | work too |
| Numbers | right-aligned |

Footnotes work as well.[^1]

[^1]: Like this one, collected at the bottom of the page.
