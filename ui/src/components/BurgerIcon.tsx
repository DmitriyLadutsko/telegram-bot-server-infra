import React from 'react';
import clsx from 'clsx';

type Props = {
    isOpen: boolean;
    onClick: () => void;
};

const BurgerIcon: React.FC<Props> = ({isOpen, onClick}) => {
    return (
        <button
            onClick={onClick}
            className="relative w-8 h-8 flex items-center justify-center z-50 focus:outline-none cursor-pointer"
        >
            <span
                className={clsx(
                    'absolute h-0.5 w-6 bg-gray-400 transform transition duration-300 ease-in-out',
                    isOpen ? 'rotate-45 translate-y-0' : '-translate-y-2'
                )}
            />
            <span
                className={clsx(
                    'absolute h-0.5 w-6 bg-gray-400 transition-all duration-300 ease-in-out',
                    isOpen ? 'opacity-0' : 'opacity-100'
                )}
            />
            <span
                className={clsx(
                    'absolute h-0.5 w-6 bg-gray-400 transform transition duration-300 ease-in-out',
                    isOpen ? '-rotate-45 translate-y-0' : 'translate-y-2'
                )}
            />
        </button>
    );
};

export default BurgerIcon;
