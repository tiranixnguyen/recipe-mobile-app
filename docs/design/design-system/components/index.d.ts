import type * as React from 'react';
export type IconName = 'search' | 'clock' | 'person' | 'heart' | 'home' | 'bowl' | 'list' | 'plus' | 'check' | 'compass' | 'fridge' | 'calendar' | 'bookmark' | 'shuffle' | 'back' | 'sliders' | 'timer' | 'minus' | 'close' | 'smile' | 'meh' | 'frown' | 'bell' | 'trash' | 'chevron' | 'alert' | 'info' | 'shield' | 'mail' | 'image' | 'sun' | 'moon' | 'device';
export interface IconProps { name: IconName; className?: string }
export declare function Icon(props: IconProps): React.ReactElement;
export interface ButtonProps extends React.ButtonHTMLAttributes<HTMLButtonElement> { variant?: 'primary' | 'secondary' | 'ghost' | 'danger'; icon?: IconName; block?: boolean; /** 'lg' = cao 56px, cho chế độ nấu */ size?: 'md' | 'lg' }
export declare function Button(props: ButtonProps): React.ReactElement;
export interface ChipProps { selected?: boolean; icon?: IconName; onClick?: () => void; children?: React.ReactNode }
export declare function Chip(props: ChipProps): React.ReactElement;
export interface SearchFieldProps { value?: string; defaultValue?: string; placeholder?: string; label?: string; onChange?: React.ChangeEventHandler<HTMLInputElement> }
export declare function SearchField(props: SearchFieldProps): React.ReactElement;
export interface AvailabilityBadgeProps { /** Nguyên liệu còn thiếu; rỗng hoặc bỏ trống = "Đủ đồ" */ missing?: string[] }
export declare function AvailabilityBadge(props: AvailabilityBadgeProps): React.ReactElement;
export interface RecipeCardProps { title: string; minutes: number; servings?: number; /** Dụng cụ chính, ví dụ "Bếp từ" */ tool?: string; /** Truyền để hiện AvailabilityBadge */ missing?: string[]; image?: string; saved?: boolean; onToggleSave?: () => void }
export declare function RecipeCard(props: RecipeCardProps): React.ReactElement;
export interface NavItem { id: string; label: string; icon: IconName }
export interface BottomNavProps { active: string; items?: NavItem[]; onChange?: (id: string) => void }
export declare function BottomNav(props: BottomNavProps): React.ReactElement;
export interface EmptyStateProps { title: string; icon?: IconName; actionLabel?: string; onAction?: () => void; children?: React.ReactNode }
export declare function EmptyState(props: EmptyStateProps): React.ReactElement;
export interface StepTimerProps { /** Thời lượng của bước, tính bằng giây */ seconds: number; /** Tên việc đang hẹn giờ, ví dụ "Chiên mặt dưới" */ label?: string; /** Bắt đầu đếm ngay khi hiện */ autoStart?: boolean; onDone?: () => void; /** Gọi khi chuyển giữa chờ / đang chạy / hết giờ */ onStatusChange?: (status: 'idle' | 'running' | 'done') => void }
export declare function StepTimer(props: StepTimerProps): React.ReactElement;
export interface ServingStepperProps { value?: number; defaultValue?: number; /** Mặc định 1 */ min?: number; /** Mặc định 6 */ max?: number; /** Mặc định "người" */ unit?: string; label?: string; onChange?: (value: number) => void }
export declare function ServingStepper(props: ServingStepperProps): React.ReactElement;
declare global { interface Window { BepHoaLac: { Button: typeof Button; Chip: typeof Chip; SearchField: typeof SearchField; AvailabilityBadge: typeof AvailabilityBadge; RecipeCard: typeof RecipeCard; BottomNav: typeof BottomNav; EmptyState: typeof EmptyState; StepTimer: typeof StepTimer; ServingStepper: typeof ServingStepper; Icon: typeof Icon } } }
