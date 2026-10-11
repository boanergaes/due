import type { SVGAttributes } from 'react';

export default function AppLogoIcon(props: SVGAttributes<SVGElement>) {
    return (
        <svg
            {...props}
            viewBox="0 0 24 24"
            fill="none"
            stroke="currentColor"
            strokeWidth="2.5"
            strokeLinecap="square"
            strokeLinejoin="miter"
            xmlns="http://www.w3.org/2000/svg"
        >
            <rect x="3" y="3" width="18" height="18" />
            <path d="M7 12l3 3 7-7" />
        </svg>
    );
}
