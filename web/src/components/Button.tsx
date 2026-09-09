import { Button as BaseButton } from '@base-ui/react/button'
import type { ComponentProps } from 'react'
import styles from './Button.module.css'

type Variant = 'primary' | 'secondary'

type ButtonProps = ComponentProps<typeof BaseButton> & {
  variant?: Variant
}

/**
 * The site's button, on Base UI. 2.25rem tall, 0.75rem side padding, 0.5rem radius.
 * Primary is the inverse surface; secondary is the sunken surface.
 * Pass `render={<a href="…" />}` to get an anchor with button styling.
 */
export function Button({ variant = 'primary', className, render, ...props }: ButtonProps) {
  const classes = [styles.button, styles[variant], className].filter(Boolean).join(' ')
  return <BaseButton className={classes} render={render} nativeButton={render === undefined} {...props} />
}
