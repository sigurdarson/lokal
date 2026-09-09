import { Button as BaseButton } from '@base-ui/react/button'
import type { ComponentProps } from 'react'
import styles from './Button.module.css'

type Variant = 'primary' | 'secondary'
type Size = 'default' | 'compact'

type ButtonProps = ComponentProps<typeof BaseButton> & {
  variant?: Variant
  size?: Size
  /** Square button holding only an icon. Pass an aria-label. */
  iconOnly?: boolean
}

/**
 * The site's button, on Base UI. 2.25rem tall (1.75rem compact), 0.5rem radius.
 * Primary is the inverse surface; secondary is the sunken surface.
 * Pass `render={<a href="…" />}` (or a router `<Link />`) to get a link with button styling.
 */
export function Button({ variant = 'primary', size = 'default', iconOnly = false, className, render, ...props }: ButtonProps) {
  const classes = [styles.button, styles[variant], size === 'compact' && styles.compact, iconOnly && styles.iconOnly, className]
    .filter(Boolean)
    .join(' ')
  return <BaseButton className={classes} render={render} nativeButton={render === undefined} {...props} />
}
